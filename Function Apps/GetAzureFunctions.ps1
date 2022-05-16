# A script to generate a report of all Azure Function within Function Apps in a particular subscription
# Requires you to already be authenticate to the subscription you would like to report on using Connect-AzAccount
# outputs to a csv at .\output.csv
$azContext = Get-AzContext
$azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
$profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
$token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
$authHeader = @{
   'Content-Type'='application/json'
   'Authorization'='Bearer ' + $token.AccessToken
}

$allFunctionApps = Get-AzFunctionApp

$allFunctions = @()

foreach ($fa in $allFunctionApps){
    $subscriptionid = $fa.SubscriptionId
    $resourceGroup = $fa.ResourceGroupName
    $name = $fa.Name
    $functions = Invoke-RestMethod  -Uri "https://management.azure.com/subscriptions/$subscriptionid/resourceGroups/$resourceGroup/providers/Microsoft.Web/sites/$name/functions?api-version=2015-08-01"  -Headers $authHeader -ContentType "application/json" -Method GET
    $allFunctions += $functions.value
}

#output is a list of custom objects
$output = @()
foreach ($function in $allfunctions) {
    $subid = Get-AzContext | select Subscription
    $sub = (Get-AzSubscription | where-object {$_.Id -eq $subid}) | select Name
    $functionappname = ($function.name -Split "/")[0]
    $functionname = ($function.name -Split "/")[1]
    $functionoutput = [PSCustomObject]@{
        functionAppName = $functionappname
        functionName = $functionname
        location = $function.location
        subscription = $sub
    }
    $output += $functionoutput
}

$output | Export-Csv -Path .\output.csv -NoTypeInformation



