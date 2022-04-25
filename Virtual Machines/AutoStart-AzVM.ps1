
## Description: Auto trigger VMs on at a set schedule. Script is set to only work on azure via AA runbook.
##
## Assumptions: Trigger via schedule from Azure Automation. Variable groups must exist beforehand. Each new time/schedule must be added
## as variable group and into a AA schedule for triggering. 

param (
    [String] $VariableGroupName
)

# Script Variables
$scriptSuccessStatus = $true
$ErrorActionPreference = "Continue"

# Authenticate to Azure
$connection = Get-AutomationConnection -Name 'AzureRunAsConnection'
$localAzProfile = Connect-AzAccount -ServicePrincipal -Tenant $connection.TenantID -ApplicationID $connection.ApplicationID `
  -CertificateThumbprint $connection.CertificateThumbprint -ErrorVariable "err" -ErrorAction SilentlyContinue


# Get Correct Variable Group
$targetVMs = $null;

# Determine which variable group (VMs) should be targeted
Try {
    $targetVMs = (Get-AutomationVariable -Name $VariableGroupName).Replace("`n","").Replace(" ","").Split(";")  
    Write-Output "Using Variable group: $VariableGroupName"  
} Catch {
    $scriptSuccessStatus = $false
    Write-Output "ERROR: Cannot find Variable group: $VariableGroupName"
    throw "ERROR: Cannot find Variable group: $VariableGroupName"
    exit 1
}


# Get all Subscriptions
$subs = Get-AzSubscription 

# Loop through subscription, check if VM from variable group exists, if true start vm
ForEach ($sub in $subs){
    Set-AzContext -Subscription $sub  | Out-Null
    Write-Output "debug-setting sub to $($sub.name)"
    $subVMs = (Get-AzVm).Name
    Write-Output "debug-finished retrieving vms"
    ForEach ($vm in $targetVMs){
        if ($vm -and ($subVMs -contains $vm)){

            # Write-Output "--- Looking for $vm in $($sub.Name)"
            $vmToStart = Get-AzVM -Name $vm
            Write-Output "debug-got vm"
            If ($vmToStart){
                Write-Output "--- Found  $vm in $($sub.Name)"
                $startVMJob = $vmToStart | Start-AzVM -AsJob
                Write-Output "--- Starting $vm on Sub:$($sub.Name)" 
                continue
            }   
        }
    } # end vm loop
} # end sub loop


Write-Output "`n======================================================================================="

# Get all start-vm jobs, and show status
$jobs = Get-Job | Wait-Job -Timeout 600

ForEach ($job in $jobs){
    Write-Output "* Id:$($job.Id) -$($job.Name) - $($job.State)"
    If ($job.State -like "*Failed*"){
        $scriptSuccessStatus = $false
        
    }

} 

Write-Output "`n======================================================================================="
Write-Output "Total successful jobs: $((Get-Job -State Completed).count)"
Write-Output "Total failed jobs: $((Get-Job -State Failed).count)"

If (!$scriptSuccessStatus){
    throw "ERROR: Job(s) failed "
    exit 1
}
