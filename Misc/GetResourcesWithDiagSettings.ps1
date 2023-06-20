$subscriptions = @("subscriptionname")

$resourcesWithDiagSettings = @()

foreach ($subscription in $subscriptions) {

    Set-AzContext -Subscription $subscription

    $allResources = Get-AzResource

    foreach ($resource in $allResources) {
        $resourceId = $resource.ResourceId
        $diagSetting = Get-AzDiagnosticSetting -ResourceId $resourceId

        if ($diagSetting -ne $null) {
            # Create a custom object to store the resource name, subscription and diagnostic setting information
            $object = New-Object PSObject
            $object | Add-Member -Type NoteProperty -Name "ResourceName" -Value $resource.Name
            $object | Add-Member -Type NoteProperty -Name "Subscription" -Value $subscription
            $object | Add-Member -Type NoteProperty -Name "DiagnosticSetting" -Value $diagSetting.Name
            $object | Add-Member -Type NoteProperty -Name "EventHubName" -Value $diagSetting.EventHubName

            # Add object to the list
            $resourcesWithDiagSettings += $object
        }
    }

}

$resourcesWithDiagSettings | Export-Csv -Path "C:\temp\resources_with_diag_settings.csv" -NoTypeInformation -Append