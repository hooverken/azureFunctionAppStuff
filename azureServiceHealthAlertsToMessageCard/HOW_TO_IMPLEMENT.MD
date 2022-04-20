# How to implement this function app in your environment

This is a basic checklist for implementing this in your environment.  This should result in a working setup, though you won't know for sure until a real service health alert gets thrown.

## Prerequisites

- An Azure Subscription
- Ownership of at least one Microsoft Teams team (or a friendly relationship with the owner of Teams in your environment)

## Creating and configuring the functionApp

- [Create an incoming webhook for the Teams channel that you want to post the alerts to](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?msclkid=36e57ebfc0e111ecabd007f617cbd546)
- Create a functionApp in Azure that uses PowerShell and a HTTP trigger.  There are a number of ways to do this, including from the Azure Portal, from [Visual Studio](https://www.c-sharpcorner.com/article/how-to-create-an-http-trigger-azure-function-app-using-visual-studio-20172/) or [Visual Studio Code](https://docs.microsoft.com/en-us/azure/azure-functions/create-first-function-vs-code-powershell), or [from the command line using Powershell](https://docs.microsoft.com/en-us/azure/azure-functions/functions-bindings-http-webhook-trigger?tabs=in-process%2Cfunctionsv2&pivots=programming-language-powershell).
- Take the URL for the Teams channel webhook and [create an application setting](https://docs.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings?msclkid=5c0fd7b1c0e211eca51c3f378885de31&tabs=portal) for the functionApp called **webhookuri** (case sensitive).  Set the value of this setting to the URL of the webhook for the Teams channel.
- Copy and paste the code from this GitHub repo into the functionApp, replacing anything that is already there.
- ***OPTIONAL*** If you want to use icons in the output based on the type of alert, update the values of the variables *informationalIconUri*, *actionRequiredIconUri*, *incidentIconUri*, *maintenanceIconUri*, *securityIconUri* and *unknownIconUri* to point to the icons that you want to use.  These variables are located on or near line 70 in the source.  *If you leave these as they are then the code will use icons that I used, but I make no promises that the URLs will exist in the future.*

## Testing the functionApp to make sure it's working

This is a Powershell-based approach, something like Postman can certainly be used here too.

- Copy the Webhook URL for the functionApp (not the Teams channel!) using the Azure portal's "Get Function URL" option.
- Download the `SampleServiceHealthAlertWebhookPayload.json` file from this repo to your local system.
- Use `Invoke-WebRequest` with the method POST and the URL of the functionApp, passing in the content of the `SampleServiceHealthAlertWebhookPayload.json` file as the body.  The functionApp should return a 200 response code and a message should appear in the Teams channel that looks similar to the sample image in this repo.  

**Do not proceed until this works as it should**

## Linking Azure Service Health Alerts to the Function App

- Create a [Azure Service Health Alert](https://docs.microsoft.com/en-us/azure/service-health/alerts-activity-log-service-notifications-portal) scoped to the subscription(s) you want to monitor.
- For the **Action Group** associated with the service health alert, choose **Webhook** (NOT Secure Webhook) as the Action Type and configure as follows:
    - **Name** can be whatever you want it to be
    - **URI** must be set to the URI of the function App you created above
    - **Enable the common alert schema MUST be set to YES** or you will get nonsense in the Teams channel

Now, whern a service health notification is generated which matches the criteria in the alert rule, you should get a message in the Teams channel.

