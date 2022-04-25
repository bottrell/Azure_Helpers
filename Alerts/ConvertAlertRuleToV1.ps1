<# 
    Descripton:
    * This script allows you to convert an alert rule v2 into an alert rule v1
    * Alert Rule V1 supports custom Email Subject, Custom JSON payload, and more refined signal logic
    * Alert Rule V1s were removed from the portal in January 2022, so all alerts created 
            after that do not have these capabilities. 

    To Run:
    * Gather the Name and Resource Group of the existing V2 alert
    * Run ./ConvertAlertRuleToV1.ps1 -Name <current alert name> -ResourceGroup <current alert RG> -Severity <severity>
    
    Optional Parameters:
    * -EvaluationFrequency - The evaluation frequency of the query. Default is 15 minutes
    * -TimeWindowInMinutes - The time window the query will run against. Default is 15 minutes.
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
    [int]$EvaluationFrequency = 15,
    [int]$TimeWindowInMinutes = 15,
    [string]$EmailSubject = "Testing",
    [bool]$DeactivateNew = $false,
    # For some reason this doesn't work right now, I'm looking into it
    # For now you'll need to manually disable the old alert rule
    [bool]$DeactivateOld = $false
)

$location = (Get-AzResourceGroup -Name $ResourceGroup).Location
$oldRule = Get-AzScheduledQueryRule -Name $Name -ResourceGroupName $ResourceGroup
# Deconstructing old alert rule and building a new rule which fits the format of V1 alerts

$oldSource = $oldRule.Source
$oldQuery = $oldSource.Query
$oldSourceID = $oldSource.DataSourceId
$newSource = New-AzScheduledQueryRuleSource -Query $oldQuery -DataSourceId $oldSourceID

# Curently there is a bug where the evaluation frequency and time window are not reflected in the new rule, so right now automatically setting everything to 15 minutes unless the user overwrites it
$newSchedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes $EvaluationFrequency -TimeWindowInMinutes $TimeWindowInMinutes

$oldMetricTrigger = $oldRule.Action.Trigger
$oldThresholdOperator = $oldMetricTrigger.ThresholdOperator
$oldThreshold = $oldMetricTrigger.Threshold
$oldTriggerType = $oldMetricTrigger.MetricTrigger.MetricTriggerType
# From my testing I believe that the Metric Column is a deprecated. I just added Name here because it's a common log analytics column
$oldTriggerMetricColumn = "Name"
$newMetricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator $oldThresholdOperator -Threshold $oldThreshold -MetricTriggerType $oldTriggerType -MetricColumn $oldTriggerMetricColumn -ErrorAction SilentlyContinue
$newTriggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator $oldThresholdOperator -Threshold $oldThreshold -MetricTrigger $newMetricTrigger

# For now, just set the CustomJSON Payload to a dummy value, require that the user goes into the portal to validate the parameters themselves
$oldAznsActionGroup = $oldRule.Action.AznsAction
$oldActionGroup = $oldAznsActionGroup.ActionGroup
$newAznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup $oldActionGroup -EmailSubject $EmailSubject -CustomWebhookPayload "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }"

$oldSeverity = $oldRule.Action.Severity
$newAlertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $newAznsActionGroup -Severity $oldSeverity -Trigger $newTriggerCondition

$description = ($oldRule.Description) + "This rule has been re-created as an alert rule V1"
$newRuleName = $Name + "_V1"

# This is the part that actually creates the new rule, for those of you who want to deconstruct this
if ($DeactivateNew -eq $true) {
    New-AzScheduledQueryRule -ResourceGroupName $ResourceGroup -Location $location -Action $newAlertingAction -Enabled $false -Description $description -Schedule $newSchedule -Source $newSource -Name $newRuleName
} else {
    New-AzScheduledQueryRule -ResourceGroupName $ResourceGroup -Location $location -Action $newAlertingAction -Enabled $true -Description $description -Schedule $newSchedule -Source $newSource -Name $newRuleName
}

# I've had about 33% luck getting this to actually work, you'll likely need to go in and disable the old alert manually
if ($DeactivateOld -eq $true) {
    Update-AzScheduledQueryRule -Name $Name -ResourceGroupName $ResourceGroup -Enabled $false
} 