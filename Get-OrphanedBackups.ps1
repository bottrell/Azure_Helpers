#Enter subscription Id's in the form of a list of strings
$subscriptions = @("1","2","3","4")

# Iterate through each subscription
foreach ($subscription in $subscriptions) {
    Set-AzContext -SubscriptionId $subscription | Out-Null
    $subscriptionName = (Get-AzContext).Name

    $RCvaults = Get-AzRecoveryServicesVault
    
    # Iterate through all Recovery Services vaults 
    foreach ($RCvault in $RCvaults) {
        $vaultName = $RCvault.Name

        Set-AzRecoveryServicesVaultContext -Vault $RCvault
        $containers = Get-AzRecoveryServicesBackupContainer -ContainerType AzureVM -VaultId $RCvault.ID 
        
        # Check if each backup belongs to a VM that exists in the subscription
        foreach ($container in $containers) {
            $vmName = $container.FriendlyName
            $rgName = $container.ResourceGroupName

            $vm = Get-AzVM -ResourceGroupName $rgName -Name $vmName -ErrorAction SilentlyContinue
            if (!$vm) {

                # If the VM doesn't exist, add it to orphanedbackups.csv spreadsheet
                # $backupItem = Get-AzRecoveryServicesBackupItem -Container $container -WorkloadType 'AzureVM' -Name $vmName
                $toExport = [psCustomObject]@{
                    'Subscription' = $subscriptionName
                    'Recovery Services Vault' = $vaultName
                    'VM Name'= $vmName
                    'Resource Group Name' = $rgName
                }

                Write-Host "Backup for $vmName is Deprecated"
                $toExport | Export-Csv ".\Orphanedbackups.csv" -append

            } else {

                # if the VM exists, write to console and then move on
                Write-Host "$vmName is protected"

            }
        }
    }    
}
