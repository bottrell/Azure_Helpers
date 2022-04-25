param (
[string]$tennant_ID,
[string]$file_Name
)

<#------------------------Functions-------------------------------#>
##R: $fileName is a valid CSV file 
##M: Nothing
##E: Returns an array representing azure VMs that need to be resized
function Load_Csv () {

    # Only loads in VMs which have a new size specified
    $vms_to_resize = Import-Csv $file_Name | where-object {$_.'New VM Size' -ine ""}
    
    return $vms_to_resize
}

##R: $vms is a valid array of azure vms
##M: Nothing
##E: Deallocates and changes the size of specified vms within azure, then restarts
function Resize_VMs ($vms) {

    foreach ($machine in $vms) {
        $rg_name = $machine."ResourceGroupName"
        $vm_name = $machine."VM Name"
        $old_vm_size = $machine."VM Size"
        $new_vm_size = $machine."New VM Size"

        Write-Host "Resizing VM:" $vm_name "from size:" $old_vm_size "to:" $new_vm_size
        Write-Host "*********************************************************************"

        #stopping the VM because specific sizes can't be applied to "on" machines
        Stop-AzVM -Name $vm_name -ResourceGroupName $rg_name -Force

        #Getting VM object and setting new size
        $vm = Get-AzVM -VMName $vm_name -ResourceGroupName $rg_name 
        $vm.HardwareProfile.VMSize = $new_vm_size
        
        #Applying change and restarting the machine
        Update-AzVM -VM $vm -ResourceGroupName $rg_name
        Start-AzVM -Name $vm_name -ResourceGroupName $rg_name
    }

}
<#------------------------End Functions--------------------------------#>


<#-----------------------------Main------------------------------------#>
#$vmobjects = Get-AzVM -ResourceGroupName $rgName
#loads data from csv
$machines = Load_csv
#Processes, applies, and restarts per changes in csv
Resize_VMs $machines




