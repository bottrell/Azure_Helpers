# ConvertAlertRuleToV1.ps1
## Description:
Alert Rule V1s supports custom Email Subject, Custom JSON payload, and more refined signal logic. Alert Rule V1s were removed from the portal in January 2022, so all alerts created after that do not have these capabilities. This script allows you to convert an alert rule v2 into an alert rule v1, which was a very highly sought after feature for SREs in my organization.

In my opinion, converting to an Alert Rule V1 allows for a much better support experience, and certain applications within my organization require a custom JSON payload for incident creation. Running this script. Let me know what you think!

## Examples:
### Alert Rule V2 Email message
![Alert Rule V2 email message](https://github.com/bottrell/Azure_Helpers/blob/main/Documentation/Images/v2email.png)
### Alert Rule V1 Email message
![Alert Rule V1 Email message](https://github.com/bottrell/Azure_Helpers/blob/main/Documentation/Images/v1email.png)
### Alert Rule V2 alert Parameters
![Alert Rule V2 alert Parameters](https://github.com/bottrell/Azure_Helpers/blob/main/Documentation/Images/v2alertparams.png )
### Alert Rule V1 alert Parameters
![Alert Rule V1 alert Parameters](https://github.com/bottrell/Azure_Helpers/blob/main/Documentation/Images/v1alertparams.png )

## To Run:
* Gather the Name and Resource Group of the existing V2 alert
* Authenticate to Az Powershell and set the correct subscription context
* Run `./ConvertAlertRuleToV1.ps1 -Name <NAME> -ResourceGroup <RG>`
    
## Optional Parameters:
* `-EvaluationFrequency <int>` - The evaluation frequency of the query. Default is 15 minutes
* `-TimeWindowInMinutes <int>` - The time window the query will run against. Default is 15 minutes.
* `-EmailSubject <Custom Email subject for Email alerts>` - The email subject of the new alert. Default is null.
* `-DeactivateNew <true/false>` - Leaves the old alert enabled and Deactivates the new alert. Default is false.
* `-DeactivateOld <true/false>` - Deactivates the old alert and Activates the new alert. Default is true.
