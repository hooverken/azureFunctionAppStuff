# How to implement this function app in your environment

This is a basic checklist for implementing this in your environment.  These steps should result in a working setup, though you won't know for sure until a real service health alert gets thrown.

These instructions are fairly manual/low-level in nature.  If you are familiar with using an IDE like Visual Studio or VS Code to create function apps then it should be pretty easy to translate these steps to those IDEs.

## Prerequisites

- An Azure subscription where you have sufficient access to create a function app and serice health alerts
- Ownership of at least one Microsoft Teams team (or a friendly relationship with the owner of Teams in your environment)

## Creating and configuring the function app

- In Teams, use the WebHook connector to [create an incoming webhook](https://docs.microsoft.com/en-us/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?msclkid=36e57ebfc0e111ecabd007f617cbd546)  for the Teams channel that you want to post the alerts to.
- Create a function app that uses PowerShell, a HTTP trigger and "Anonymous" authentication.
- Create an [application setting](https://docs.microsoft.com/en-us/azure/azure-functions/functions-how-to-use-azure-function-app-settings?msclkid=5c0fd7b1c0e211eca51c3f378885de31&tabs=portal) for the function app called **webhookuri** (case sensitive).  For the value, paste in the complete URI of the webhook for the Teams channel.  This setting is exposed to the function app's code as an environment variable.
- **Replace the placeholder code for the function app with the contents of the .ps1 file from this GitHub repo.**  This is the code that gets executed when the function app is triggered.

#### A note about icons

The code includes links to a set of free icons (from [icon-icons.com](https://icon-icons.com)) which reside in an Azure blob container and used in the generated message.  

If you want to substitute different icons, update the values of the variables *informationalIconUri*, *actionRequiredIconUri*, *incidentIconUri*, *maintenanceIconUri*, *securityIconUri* and *unknownIconUri* to point to the icons that you want to use.  These variables are set on or near line 70 in the source.  

*If you don't touch anything then everything will work fine but I make no promises that the icons will not change or that the links will always be functional.*

## TEST the function app to make sure it's working

This is a command-line approach. A utility like [Postman](https://www.postman.com/) can certainly be used here too if you're handy with it.

- Copy the webhook URL for the function app (not the one for the Teams channel!) using the Azure portal's "Get Function URL" option.
- Download the `SampleServiceHealthAlertWebhookPayload.json` file from this repo to your local system.
- Use `Invoke-WebRequest` with the method POST and the URL of the function app, passing in the content of the `SampleServiceHealthAlertWebhookPayload.json` file as the body.  The function app should return a 200 response code and a message should appear in the Teams channel that looks generally similar to the sample image in this repo.  

#### Do not do the last step until the test works as it should

## Link an Azure Service Health Alert to your new Function App

- Create a [Azure Service Health Alert](https://docs.microsoft.com/en-us/azure/service-health/alerts-activity-log-service-notifications-portal) scoped to the resources you want to monitor.
- For the **Action Group** associated with the service health alert, choose **Webhook** (NOT Secure Webhook) as the **Action Type** and configure as follows:
    - **Name** can be whatever you want it to be
    - **URI** must be set to the **URL of the function App**
    - **Enable the common alert schema** MUST be set to **YES**

Now, when a service health notification is generated which matches the criteria in the alert rule, you should get a message in the Teams channel.
