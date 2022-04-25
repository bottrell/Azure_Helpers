# Managed disks: Find and delete unattached disks
#Set deleteUnattachedDisks=1 if you want to delete unattached Managed Disks
# Set deleteUnattachedDisks=0 if you want to see the Id of the unattached Managed Disks
$deleteUnattachedDisks=0

$managedDisks = Get-AzDisk
$allitems = @()

foreach ($md in $managedDisks) {
    #Write-Host $md.Name
    # ManagedBy property stores the Id of the VM to which Managed Disk is attached to
    # If ManagedBy property is $null then it means that the Managed Disk is not attached to a VM
    if($null -eq $md.ManagedBy ){
           $orphaneddisk = [PSCustomObject]@{
            Name = $md.Name
            Size = $md.DiskSizeGB
            ResourceGroupName = $md.ResourceGroupName
            ManagedBy = $md.ManagedBy
        }
        $allitems += $orphaneddisk
    }
 }

 foreach ($x in $allitems) {
    $x
    Remove-AZDisk -Name $x.name -resourcegroupname $x.ResourceGroupName -force
}
