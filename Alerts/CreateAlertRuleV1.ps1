param (
    [string]$_query = "FunctionAppLogs | where Level != 'Information' | where TimeGenerated > ago(30m)",
    [string]$_sourceID = "784cdc23-d639-4b1d-8a94-84a831eb28a5",
    [int]$_frequencyInMinutes = 5,
    [int]$_timeWindowInMinutes = 5,
    [string]$_thresholdOperator = "GreaterThan",
    [int]$_severity = 3,
    [int]$_threshold = 0,
    [string]$_metricTriggerType = "Consecutive",
    [string]$_metricColumn = "message",
    [string]$_alertGroupId = "/subscriptions/200e0872-988c-4a16-899a-7b7e832f2aee/resourceGroups/rg-ea2-core-data-s2rbh-int/providers/microsoft.insights/actionGroups/sre alerts group",
    [string]$_emailSubjectLine = "Testing custom email subject line with powershell",
    [string]$_customJsonPayload = "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }",
    [string]$_resourceGroupName = "rg-ea2-monitoring-h9ed5-int"
)

$source = New-AzScheduledQueryRuleSource -Query 'Heartbeat | summarize AggregatedValue = count() by bin(TimeGenerated, 5m), _ResourceId' -DataSourceId "/subscriptions/200e0872-988c-4a16-899a-7b7e832f2aee/resourceGroups/rg-ea2-monitoring-h9ed5-int/providers/Microsoft.OperationalInsights/workspaces/log-ea2-core-h9ed5-int"
$schedule = New-AzScheduledQueryRuleSchedule -FrequencyInMinutes 15 -TimeWindowInMinutes 30
$metricTrigger = New-AzScheduledQueryRuleLogMetricTrigger -ThresholdOperator "GreaterThan" -Threshold 2 -MetricTriggerType "Consecutive" -MetricColumn "_ResourceId"
$triggerCondition = New-AzScheduledQueryRuleTriggerCondition -ThresholdOperator "LessThan" -Threshold 5 -MetricTrigger $metricTrigger
$aznsActionGroup = New-AzScheduledQueryRuleAznsActionGroup -ActionGroup "/subscriptions/200e0872-988c-4a16-899a-7b7e832f2aee/resourceGroups/rg-ea2-core-data-s2rbh-int/providers/microsoft.insights/actionGroups/sre alerts group" -EmailSubject "testing" -CustomWebhookPayload "{ `"alert`":`"#alertrulename`", `"IncludeSearchResults`":true }"
$alertingAction = New-AzScheduledQueryRuleAlertingAction -AznsAction $aznsActionGroup -Severity "3" -Trigger $triggerCondition


New-AzScheduledQueryRule -ResourceGroupName "rg-ea2-monitoring-h9ed5-int" -Location "East US 2" -Action $alertingAction -Enabled $true -Description "Testing Powershell Integration" -Schedule $schedule -Source $source -Name "JJB Test"