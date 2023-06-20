$subscriptions = @("subscriptionname")


# Define the results array
$results = @()

foreach ($subscription in $subscriptions) {
    # Set the subscription context
    Set-AzContext -Subscription $subscription

    # Get all app services in the subscription
    $appServices = Get-AzWebApp

    foreach ($appService in $appServices) {
        # Check if the Dynatrace site extension is installed in the app service
        $siteExtensions = Get-AzWebAppSiteExtension -WebApp $appService
        $dynatraceExtension = $siteExtensions | Where-Object { $_.Id -like "*dynatrace*" }

        if ($dynatraceExtension) {
            $results += New-Object PSObject -Property @{
                'Subscription' = $subscription
                'AppServiceName' = $appService.Name
                'SlotName' = $null
            }
        }

        # Check for the Dynatrace site extension in each deployment slot
        $slots = Get-AzWebAppSlot -Name $appService.Name -ResourceGroupName $appService.ResourceGroupName

        foreach ($slot in $slots) {
            $siteExtensions = Get-AzWebAppSlotSiteExtension -WebApp $appService -Slot $slot.Name
            $dynatraceExtension = $siteExtensions | Where-Object { $_.Id -like "*dynatrace*" }

            if ($dynatraceExtension) {
                $results += New-Object PSObject -Property @{
                    'Subscription' = $subscription
                    'AppServiceName' = $appService.Name
                    'SlotName' = $slot.Name
                }
            }
        }
    }
}

# Export the results to a CSV file
$results | Export-Csv -Path "C:\temp\DynatraceExtensions.csv" -NoTypeInformation