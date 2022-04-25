## Work in Progress

param (
    [string]$_query = "FunctionAppLogs | where Level != 'Information' | where TimeGenerated > ago(30m)",
    [string]$_sourceID = "",
    [int]$_frequencyInMinutes = 5,
    [int]$_timeWindowInMinutes = 5,
    [string]$_thresholdOperator = "GreaterThan",
    [int]$_severity = 3,
    [int]$_threshold = 0,
    [string]$_metricTriggerType = "Consecutive",
    [string]$_metricColumn = "message",
    [string]$_alertGroupId = "",
    [string]$_emailSubjectLine = "Testing custom email subject line with powershell",
    [string]$_customJsonPayload = "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }",
    [string]$_resourceGroupName = "rg-ea2-monitoring-h9ed5-int"
)

$source = New-AzScheduledQueryRuleSource -Query 'Heartbeat | summarize AggregatedValue = count() by bin(TimeGenerated, 5m), _ResourceId' -DataSourceId ""
$schedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes 15 -TimeWindowInMinutes 30
$metricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator "GreaterThan" -Threshold 2 -MetricTriggerType "Consecutive" -MetricColumn "_ResourceId"
$triggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator "LessThan" -Threshold 5 -MetricTrigger $metricTrigger
$aznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup "" -EmailSubject "testing" -CustomWebhookPayload "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }"
$alertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $aznsActionGroup -Severity "3" -Trigger $triggerCondition


New-AzScheduledQueryRule -ResourceGroupName "rg-ea2-monitoring-h9ed5-int" -Location "East US 2" -Action $alertingAction -Enabled $true -Description "Testing Powershell Integration" -Schedule $schedule -Source $source -Name "JJB Test"