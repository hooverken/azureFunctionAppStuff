
**ASHWebhookToMessageCardFn.ps1** is PowerShell code For a function app which posts Azure Service Health alerts to a Teams channel

While it was created to post messages to Teams, the MessageCard format that is used for the output is consumable by several Microsoft tools such as Outlook so it could potentially be used for other targets.

See the HOW_TO_IMPLEMENT.md file in this repo for how to get this working in your environment.

Below is an example (using dummy data) of what the generated message card might look like.  

![Sample Image](https://github.com/hooverken/azureFunctionAppStuff/blob/main/azureServiceHealthAlertsToMessageCard/TestServiceHealthAlertCard.PNG?raw=true)
