# ASHWebhookToMessageCard.ps1 (for Azure Powershell function app) 
# by Ken Hoover <kendothooveratmicrosoftdotcom>
# Original version August 2019
# Reimplemented for Kentoso.us demo/lab environment April 2022
#
# This is Powershell code for a very simple Azure function app to parse an incoming webhook generated by a Service 
# Health alert and turn it into a MessageCard which is then sent to a destination such as Teams via an outgoing 
# webhook.  It can probably be adapted fairly easily to send webhooks to other recipients like Slack.

# This code was based on a lot of experimentation.  it can probably be mode more bulletproof but it is functional
# Use at your own risk

# This assumes that the incoming webhook uses the Common Alert Schema and is a Service Health Alert
# https://docs.microsoft.com/en-us/azure/azure-monitor/platform/alerts-common-schema-definitions#monitoringservice--servicehealth

#
# IMPORTANT:  The webhook uri to send the outgoing messageCard (which in my case was for a Teams channel) to needs to
# be set as an environment variable for the functionApp named "webhookuri".  
# This is done using the "Application Settings" for the FunctionApp and is referenced in the code as an environment variable.
#

using namespace System.Net

# Incoming data from the trigger
param ( $Request, $TriggerMetadata )


# Write to the Azure Functions log stream.
Write-Host "PowerShell HTTP trigger function received a request."

####### Setup stuff 

# Get the payload from the incoming webhook as an object
$payload = ($request.rawbody | convertfrom-json)


# Get the subscription ID that this alert is for from the payload
$subscriptionId = $payload.data.essentials.alertid.split('/')[2] 

# Start assembling the message card from the payload data

# This script uses the legacy-but-simpler O365 "Message Card" format described at 
#    https://docs.microsoft.com/en-us/outlook/actionable-messages/message-card-reference

# In the future this should be upgraded to the newer-but-more-complex "Adaptive Card" format 
#    https://docs.microsoft.com/en-us/microsoftteams/platform/concepts/cards/cards-reference#adaptive-card


$MessageCard = @{}
$sections = @() ; $SectionsHash = @{}
$MessageCard.Add("@type", "MessageCard")
$MessageCard.Add("@context", "http://schema.org/extensions")
$MessageCard.Add("summary", $payload.data.alertcontext.properties.title)
$MessageCard.Add("title", "Microsoft Azure Service Health Alert")
$MessageCard.Add("text", ("**Subscription ID " + $subscriptionId + "**" ))

# Set the theme color for the message card based on the event "stage"

# Possible stages are:  Active, Planned, InProgress, Canceled, Rescheduled, Resolved, Complete and RCA

# Different incident types use different subsets of the possible stages so some types of alerts will be presented differently based
# on their urgency.  This should limit the amount of red that comes through.
$red = "FF0000" ; $yellow = "FFFF00" ; $blue = "000000" ; $green = "008000"

# These URLs point to PNG icons that will be displayed next to the title of the message card
# The icons I'm using here were downloaded from https://icon-icons.com but there are tons of free ones out there.
# The access level to the container should be set to "Blob (anonymous read access for blobs only)"

$informationalIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/information_info_1565.png'
$actionRequiredIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/uparrow_up_up_arrow_theaction_6341.png'
$incidentIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/sign-warning-icon_34355.png'
$maintenanceIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/maintenance256_24835.png'
$securityIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/padlock_78356.png'
$defaultIconUri = 'https://kentososervicehealt8624.blob.core.windows.net/activity-icons/information_info_1565.png'

switch ($payload.data.alertcontext.properties.IncidentType) {
    "Informational" { 
        $MessageCard.Add("themeColor", $blue)  # Color for informational alerts
        $SectionsHash.Add("activityImage", $informationalIconUri)
    }
    "ActionRequired" {
        $MessageCard.Add("themeColor", $yellow)
        $SectionsHash.Add("activityImage", $actionRequiredIconUri)
    }
    "Incident" {  # apply different themes based on the alert stage.
        $SectionsHash.Add("activityImage", $incidentIconUri)
        switch ($payload.data.alertcontext.properties.stage) {
            "Active" {
                $MessageCard.Add("themeColor", $red)
            }
            "Resolved" {
                $MessageCard.Add("themeColor", $yellow)
            }
            "RCA" {
                $MessageCard.Add("themeColor", $blue)
            }
        }
    }
    "Maintenance" {
        $MessageCard.Add("themeColor", $green)
        $SectionsHash.Add("activityImage", $maintenanceIconUri)
    }
    "Security" {      \
        $SectionsHash.Add("activityImage", $securityIconUri)  
        switch ($payload.data.alertcontext.properties.stage) {
            "Active" {
                $MessageCard.Add("themeColor", $red)
            }
            "Resolved" {
                $MessageCard.Add("themeColor", $yellow)
            }
            "RCA" {
                $MessageCard.Add("themeColor", $blue)
            }
        }
    }
    Default { # in case something comes through that we don't recognize
        $SectionsHash.Add("activityImage", $defaultIconUri)
        $MessageCard.Add("themeColor", $yellow)
    }
}


$SectionsHash.Add("activityTitle", ("# " + $payload.data.alertcontext.properties.title))
$SectionsHash.Add("activitySubTitle",("# Alert State: " + $payload.data.alertcontext.properties.stage))

# Copy the properties of the payload (a list of name-value pairs) into the card's "facts" section
$facts = $payload.data.alertcontext.properties
if($null -ne $facts){
    $factsCollection = @()
    foreach($fact in $Facts) {
        $Fact.psobject.properties | ForEach-Object {
            # skip redundant fields and ones that have data that won't parse cleanly
            if (!( ($_.name.tostring().contains("default")) -or ($_.name.tostring().contains("impactedServices")) )) {
                $factsCollection += @{"name"=$_.name ; "value"=$_.value }
            }
        }
    }
    $SectionsHash.Add("facts",$factsCollection)
}

$Sections += $SectionsHash 
$MessageCard.Add("sections", $Sections)

##
# Now add the actions part of the card.  This is where we put buttons and such to let users take an action right from the card.
# In this example we're just adding a button to open the service health issues blade in the Azure portal.
#
# Ref: https://docs.microsoft.com/en-us/outlook/actionable-messages/message-card-reference#actions
#
$potentialActions = @() ; 
$potentialActionsHash = @{}
$potentialActionsHash.Add("@type","openuri")
$potentialActionsHash.Add("name","Go to Service Health Page")
$targetsList = @() ; $targetsHash = @{}
$targetsHash.Add("os","default")
$targetsHash.Add("uri","https://portal.azure.com/#blade/Microsoft_Azure_Health/AzureHealthBrowseBlade/serviceIssues")
$targetslist += $targetsHash
$potentialActionsHash.Add("targets",$targetslist)
$potentialActions += $potentialActionsHash

$messageCard.add("potentialAction",$potentialActions)

### Send the message card to Teams

# Now that we have the message card, convert it to JSON so it can be sent as the body of the outgoing webhook
$messageCardJSON = $messageCard | ConvertTo-Json -Depth 15

####### Now that the MessageCard is complete, send the outgoing webhook(s) to post the card
invoke-webrequest -method POST -uri $env:webhookuri -body $messageCardJSON


# Associate values to output bindings by calling 'Push-OutputBinding'.
Push-OutputBinding -Name Response -Value ([HttpResponseContext]@{
    StatusCode = [HttpStatusCode]::OK
    Body = $messageCardJSON
})
