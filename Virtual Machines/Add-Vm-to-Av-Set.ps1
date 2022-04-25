param (
    [string]$ResourceGroupName,
    [string]$VirtualMachineName,
    [string]$AVSetName
)

<#------------------------Functions-------------------------------#>

##Requires: No AvSet exists with name $AVSetName in $ResourceGroupName. $Vm must be a valid virtual machine within the current subscription
##Modifies: Subscription
##Effects: Returns an Availability Set corresponding to $AVSetName
function New-AvSet ($old_vm) {
    Write-Host "**********************************"
    Write-Host "**Creating new AV Set $AVSetName**"
    Write-Host "**********************************"

    #Location represents region of original VM referenced in parameters
    $Location = $old_vm.Location

    #$FaultDC represents PlatformFaultDomainCount
    $FaultDC = 3

    #$UpdateDC represents PlatformUpdateDomainCount
    $UpdateDC = 5

    #Create the Availability Set
    $NewAvSet = New-AzAvailabilitySet -Location $Location -Name $AVSetName -ResourceGroupName $ResourceGroupName -PlatformFaultDomainCount $FaultDC -PlatformUpdateDomainCount $UpdateDC -Sku Aligned

    Return $NewAvSet
}

##Requires: A VM exists with name $VirtualMachineName
##Modifies: Nothing
##Effects: Returns a hash table with information corresponding to existing VM
function Save-VmConfig ($old_VM) {
    Write-Host "**********************************"
    Write-Host "*****Caching VM Configuration*****"
    Write-Host "**********************************"
    #Goes through each variable within old_vm and saves them to the $config hash table
    $Config = @{}

    $Config.Name = $old_VM.name
    $Config.Size = $old_VM.HardwareProfile.VmSize
    $Config.Location = $old_VM.Location

    #Gets an array of the data disks attached to old VM
    $Config.DataDisks = $old_VM.StorageProfile.DataDisks

    #Gets the name and Id of the OS Disk associated with old VM
    $Config.OsDisk = $old_VM.StorageProfile.OsDisk.ManagedDisk.Id
    $Config.OsDiskName = $old_VM.StorageProfile.OsDisk.Name

    #Get Network Interface Cards from original VM
    $Config.Nics = $old_VM.NetworkProfile.NetworkInterfaces

    Return $Config
}

##Requires: $vmconfig is a valid, populated hash table
##modifies: Azure Subscription
##Effects: Creates a new Vm and applies the configuration of the original VM
function New-VM ($vmconfig, $avsetid) {
    Write-Host "**********************************"
    Write-Host "**Creating new VM $VirtualMachineName**"
    Write-Host "**********************************"

    #Creates the configuration template for the new VM
    $template = New-AzVmConfig -VMName $vmconfig.Name -VMSize $vmconfig.Size -AvailabilitySetId $avsetid 

    #Add OS Disk to New VM configuration
    Set-AzVMOSDisk -VM $template -CreateOption Attach -ManagedDiskId $vmconfig.OsDisk -Name $vmconfig.OsDiskName -Windows

    #Add Data drives to VM configuration
    foreach ($drive in $vmconfig.DataDisks) {
        Add-AzVMDataDisk -VM $template -Name $drive.Name -ManagedDiskId $drive.ManagedDisk.Id -Caching $drive.Caching -Lun $drive.Lun -DiskSizeInGB $drive.DiskSizeGB -CreateOption Attach 
    }

    #Add network card from old VM to new VM
    #Note: Public IP should be associated with Primary Nic already, and thus should not need to be manually added
    foreach ($nic in $vmconfig.Nics) {
        if ($nic.Primary -eq "True") {
            Add-AzVMNetworkInterface -VM $template -Id $nic.Id -Primary
        } else {
            Add-AzVMNetworkInterface -VM $template -Id $nic.Id
        }
    }

    #Creating the new VM
    New-AzVM -ResourceGroupName $ResourceGroupName -Location $vmconfig.Location -VM $template 

    Write-Host "**********************************"
    Write-Host "****Finished Creating new VM*****"
    Write-Host "**********************************"
}
<#------------------------End Functions--------------------------------#>

<#-----------------------------Main------------------------------------#>
#Get Resource Group and VM objects (You may assume these exist within the current subscription)
$ResourceGroup = Get-AzResourceGroup -Name $ResourceGroupName
$VirtualMachine = Get-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName

#Check if $VirtualMachine is already in an avset (if so, exit)
if ($null -ne $VirtualMachine.AvailabilitySetReference) {
    Write-Output "VM $VirtualMachineName is already in an availability set. Exiting..."
    return $null
} 

#Create an AVset if it doesn't already exist
$AvailabilitySet = Get-AzAvailabilitySet -ResourceGroupName $ResourceGroupName -Name $AVSetName -ErrorAction Ignore

if ($null -eq $AvailabilitySet) {
    #Creat-AvSet Returns a reference to an availability set object (probably won't need it, but better to have it around for testing purposes)
    $AvailabilitySet = New-AvSet $VirtualMachine
}

#Save configuration details of original Virtual Machine 
$config = Save-VmConfig $VirtualMachine

#Delete VM object (but preserve everything else)
Write-Host "**********************************"
Write-Host "**Removing Old VM $VirtualMachineName**"
Write-Host "**********************************"
Remove-AzVM -ResourceGroupName $ResourceGroupName -Name $VirtualMachineName -Force

#Create New VM, attaching existing NIC, disk, vnet, subnet, etc. from old VM
New-VM $config $AvailabilitySet.Id