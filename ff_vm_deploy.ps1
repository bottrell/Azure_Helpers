param (
    [string]$resourceGroupName
    [int]$numVms
)

#--------------------Constants------------------#
$subnetName = ""
$vnetName = ""
$location = ""
$imageName = ""
$imagePath = ""
$sku = "Standard_D4s_v4"
$localuser = ""
$localpass = ""

#-----------------------Main--------------------#
$cred = Get-Credential -Message "Enter a username and password for the virtual machines"
$numVms = 15
for ($vm = 1; $vm -le $numVms; $vm++) {
    if ($vm -lt 10) {

        $vmName = "devwu2acc0$vm"
        $vm = 1
        #creating the NIC for each VM
        $vnet = Get-AzVirtualNetwork -ResourceGroupName "prd-wus2-vnet-rg" -Name "prd-wus2-vnet01"
        $subnetConfig = Get-AzVirtualNetworkSubnetConfig -Name "prd-wus2-data" -VirtualNetwork $vnet
        $nic = New-AzNetworkInterface -Name "devwu2acc0$vm-nic01" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnetConfig.Id 

        #creating the virtual machine from the shared image
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D4s_v4 | `
        Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
        Set-AzVMSourceImage -Id $imagePath | `
        Add-AzVMNetworkInterface -Id $nic.Id 

        New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
        Restart-AZVm -ResourceGroupName $resourceGroupName -name $vmName
        Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
        Start-sleep -Seconds 60
        Start-AzVM -ResourceGroupName -Name $vmName

        write-host $vm

    } else {
      
        $vmName = "devwu2acc$vm"
        $vm = 1
        #creating the NIC for each VM
        $vnet = Get-AzVirtualNetwork -ResourceGroupName "prd-wus2-vnet-rg" -Name "prd-wus2-vnet01"
        $subnetConfig = Get-AzVirtualNetworkSubnetConfig -Name "prd-wus2-data" -VirtualNetwork $vnet
        $nic = New-AzNetworkInterface -Name "devwu2acc$vm-nic01" -ResourceGroupName $resourceGroupName -Location $location -SubnetId $subnetConfig.Id 

        #creating the virtual machine from the shared image
        $vmConfig = New-AzVMConfig -VMName $vmName -VMSize Standard_D4s_v4 | `
        Set-AzVMOperatingSystem -Windows -ComputerName $vmName -Credential $cred | `
        Set-AzVMSourceImage -Id $imagePath | `
        Add-AzVMNetworkInterface -Id $nic.Id 

        New-AzVM -ResourceGroupName $resourceGroupName -Location $location -VM $vmConfig
        Restart-AZVm -ResourceGroupName $resourceGroupName -name $vmName
        Stop-AzVM -ResourceGroupName $resourceGroupName -Name $vmName
        Start-sleep -Seconds 60
        Start-AzVM -ResourceGroupName -Name $vmName

        write-host $vm

    }
}
