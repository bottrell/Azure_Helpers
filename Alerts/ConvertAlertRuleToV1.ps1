<# 
    Descripton:
    * This script allows you to convert an alert rule v2 into an alert rule v1
    * Alert Rule V1 supports custom Email Subject, Custom JSON payload, and more refined signal logic
    * Alert Rule V1s were removed from the portal in January 2021, so all alerts created 
            after that do not have these capabilities. 

    To Run:
    * Gather the Name and Resource Group of the existing V2 alert
    * Run ./ConvertAlertRuleToV1.ps1 -Name <current alert name> -ResourceGroup <current alert RG> -Severity <severity>
    
    Optional Parameters:
    * -EmailSubject <Custom Email subject for Email alerts> - The email subject of the new alert. Default is null.
    * -DeactivateNew <true/false> - Leaves the old alert enabled and Deactivates the new alert. Default is false.
    * -DeactivateOld <true/false> - Deactivates the old alert and Activates the new alert. Default is true.
#> 
param (
    # Required Parameters
    [Parameter(Mandatory=$true)]
    [string]$Name,
    [Parameter(Mandatory=$true)]
    [string]$ResourceGroup,

    # Optional Parameters
    [string]$EmailSubject = "Testing",
    [bool]$DeactivateNew = $false,
    [bool]$DeactivateOld = $true
)

$oldRule = Get-AzScheduledQueryRule -Name $Name -ResourceGroupName $ResourceGroup
# Deconstructing old alert rule and building a new rule which fits the format of V1 alerts

$oldSource = $oldRule.Source
$oldQuery = $oldSource.Query
$oldSourceID = $oldSource.DataSourceId
$newSource = New-AzScheduledQueryRuleSource -Query $oldQuery -DataSourceId $oldSourceID

$oldSchedule = $oldRule.Schedule
$oldFrequency = $oldSchedule.FrequencyInMinutes
$oldTimeWindow = $oldSchedule.TimeWindowInMinutes
$newSchedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes $oldFrequency -TimeWindowInMinutes $oldTimeWindow

$oldMetricTrigger = $oldRule.Action.Trigger
$oldThresholdOperator = $oldMetricTrigger.ThresholdOperator
$oldThreshold = $oldMetricTrigger.Threshold
$oldTriggerType = $oldMetricTrigger.MetricTrigger.MetricTriggerType
$oldTriggerMetricColumn = ""
$newMetricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator $oldThresholdOperator -Threshold $oldThreshold -MetricTriggerType $oldTriggerType -MetricColumn $oldTriggerMetricColumn -ErrorAction SilentlyContinue
$newTriggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator $oldThresholdOperator -Threshold $oldThreshold -MetricTrigger $newMetricTrigger

$oldAznsActionGroup = $oldRule.Action.AznsAction
$oldActionGroup = $oldAznsActionGroup.ActionGroup
$newAznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup $oldActionGroup -EmailSubject $EmailSubject -CustomWebhookPayload "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }"

$oldSeverity = $oldRule.Action.Severity
$newAlertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $newAznsActionGroup -Severity $oldSeverity -Trigger $newTriggerCondition

$description = ($oldRule.Description) + "This rule has been re-created as an alert rule V1"
$newRuleName = $Name + "_V1"
$location = (Get-AzResourceGroup -Name $ResourceGroup).Location

if ($EmailSubject -ne "") {
    $action.AznsAction.EmailSubject = $EmailSubject
}

if ($DeactivateNew -eq $true) {
    New-AzScheduledQueryRule -ResourceGroupName $ResourceGroup -Location $location -Action $newAlertingAction -Enabled $false -Description $description -Schedule $newSchedule -Source $newSource -Name $newRuleName
} else {
    New-AzScheduledQueryRule -ResourceGroupName $ResourceGroup -Location $location -Action $newAlertingAction -Enabled $true -Description $description -Schedule $newSchedule -Source $newSource -Name $newRuleName
}

if ($DeactivateOld -eq $true) {
    Update-AzScheduledQueryRule -Name $Name -ResourceGroupName $ResourceGroup -Enabled $false
} 