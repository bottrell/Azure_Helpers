$vms = Get-AzVM 

foreach ($vm in $vms) {
    $rgName = $vm.ResourceGroupName
    $vmName = $vm.Name
    #check if the VM is running
    $vmStatus = ((Get-Azvm -ResourceGroupName $rgName -name $vmName -Status).Statuses[1].DisplayStatus)
    if ($vmStatus -eq "VM running") { 
        Write-Host "Checking D:\ Drive of $vmName. Please Wait..."

        #Grab every item on the D:\ Drive of each running machine
        $result = Invoke-AzVMRunCommand -ResourceGroupName $rgName -VMName $vmName -CommandId 'RunPowerShellScript' -ScriptPath "Get-DriveItems.ps1"

        #Change results into a string and only include the data that we care about
        $resultOutput = Out-String -InputObject $result
        $resultSplit = ($resultOutput -Split "Value")[1]
        $resultSplit = ($resultSplit -Split "Mode")[1]
        
        #number of newlines corresponds to number of items returned
        $count = (($resultSplit -Split "\n").Count - 5)

        $output = New-Object psobject
        $output | Add-Member -MemberType NoteProperty -name Name -Value $vmName
        $output | Add-Member -MemberType NoteProperty -name Output -Value $resultSplit.trim()
        $output | Add-Member -MemberType NoteProperty -Name Count  -Value $count

        $output | Export-Csv ".\tempdata.csv" -NoTypeInformation -Append
    }
}
