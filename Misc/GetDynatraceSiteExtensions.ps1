$apiVersion = "2019-08-01"
$csvOutputPath = "C:\temp\DynatraceExtensions.csv"

# Get all subscriptions
$subscriptions = @("subscriptionname")

$realsubs = @()
foreach ($sub in $subscriptions) {
    $realsubs += Get-AzSubscription -SubscriptionName $sub
}

# Prepare CSV file with headers
"SubscriptionId,SubscriptionName,ResourceGroupName,AppServiceName,SlotName" | Out-File $csvOutputPath

# Loop over all subscriptions
foreach ($subscription in $realsubs) {
    # Select subscription
    Set-AzContext -Subscription $subscription.Id

    # Get access token for REST API
    $token = (Get-AzAccessToken).Token
    $headers = @{
        'Authorization' = "Bearer $token"
        'Content-Type'  = 'application/json'
    }

    # Get all app services in the subscription
    $appServices = Get-AzWebApp

    # Loop over all app services
    foreach ($appService in $appServices) {
        Write-Host "getting app service"
        Write-Host $appService.Name

        $url = "https://management.azure.com/subscriptions/$($subscription.Id)/resourceGroups/$($appService.ResourceGroup)/providers/Microsoft.Web/sites/$($appService.Name)/siteextensions?api-version=$apiVersion"
        $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

        # Check if any Dynatrace extension is installed
        if ($response.value.id -like "*Dynatrace*") {
            "$($subscription.Id),$($subscription.Name),$($appService.ResourceGroup),$($appService.Name)," | Out-File $csvOutputPath -Append
        }

        # Get all slots for the app service
        $slots = Get-AzWebAppSlot -ResourceGroupName $appService.ResourceGroup -Name $appService.Name

        # Loop over all slots
        foreach ($slot in $slots) {
            $url = "https://management.azure.com/subscriptions/$($subscription.Id)/resourceGroups/$($appService.ResourceGroup)/providers/Microsoft.Web/sites/$($appService.Name)/slots/$($slot.Name)/siteextensions?api-version=$apiVersion"
            $response = Invoke-RestMethod -Method Get -Uri $url -Headers $headers

            # Check if any Dynatrace extension is installed
            if ($response.value.id -like "*Dynatrace*") {
                "$($subscription.Id),$($subscription.Name),$($appService.ResourceGroup),$($appService.Name),$($slot.Name)" | Out-File $csvOutputPath -Append
            }
        }
    }
}
