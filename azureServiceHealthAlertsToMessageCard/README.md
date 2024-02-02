
**ASHWebhookToMessageCardFn.ps1** is PowerShell code For a function app which posts [Azure service health alerts](https://learn.microsoft.com/azure/service-health/alerts-activity-log-service-notifications-portal) **and** [resource health alerts](https://learn.microsoft.com/azure/service-health/resource-health-alert-monitor-guide) to a Teams channel using a [Webhook connector](https://learn.microsoft.com/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook?tabs=dotnet) on the Teams channel.

This code was updated in Feb 2024 to use the more modern/flexible "[AdaptiveCard](https://learn.microsoft.com/adaptive-cards/)" format/schema.  While it was created to post messages to Teams, an AdaptiveCard consumable by several Microsoft tools/services such as Outlook so it could potentially be used for other targets.

See the HOW_TO_IMPLEMENT.md file in this repo for instructions to get this working in your environment.

## Examples:

### Service Health Alert

![Service health alert](https://github.com/hooverken/azureFunctionAppStuff/blob/main/azureServiceHealthAlertsToMessageCard/serviceHealthAlertExample.png?raw=true)

### Resource Health Alert

![Resource health alert](https://github.com/hooverken/azureFunctionAppStuff/blob/main/azureServiceHealthAlertsToMessageCard/resourceHealthAlertExample.png?raw=true)

