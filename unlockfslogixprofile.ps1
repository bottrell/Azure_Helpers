Param(
[Parameter(Mandatory=$true,HelpMessage="Enter the value for the source storage account")][String]$StorageAccountName,
[Parameter(Mandatory=$true,HelpMessage="Enter the value for file share name")][String]$FileShareName,
[Parameter(Mandatory=$true,HelpMessage="Enter the value for the storage account's resource group name")][String]$ResourceGroupName,
[Parameter(Mandatory=$true,HelpMessage="Enter the name of the user profile")][string]$username
)

$skip = $true # used for debugging in VsCode
if ( !$skip ) {
    $connectionName = "AzureRunAsConnection"
    try {
        # Get the connection "AzureRunAsConnection "
        $servicePrincipalConnection = Get-AutomationConnection -Name $connectionName         
        "Logging in to Azure..."
        Add-AzAccount `
            -ServicePrincipal `
            -TenantId $servicePrincipalConnection.TenantId `
            -ApplicationId $servicePrincipalConnection.ApplicationId `
            -CertificateThumbprint $servicePrincipalConnection.CertificateThumbprint 
        }
    catch {
        if (!$servicePrincipalConnection) {
            $ErrorMessage = "Connection $connectionName not found."
            throw $ErrorMessage
        }
        else {
            Write-Error -Message $_.Exception
            throw $_.Exception
        }
    }
}

$storage = Get-AzStorageAccount -Name $StorageAccountName -ResourceGroupName $ResourceGroupName
$UserPath = Get-AzStorageFileHandle -ShareName $FileShareName -Context $storage.context -Recursive | ? {$_.path -like "*$username*"}
$UserPath
$Paths = $UserPath.Path
$Paths
Write-Output "Assigning Variables...`n"
foreach ($Path in $Paths) {
    Close-AzStorageFileHandle -ShareName $FileShareName -Path $Path -Context $storage.context -CloseAll
}

Write-Output "Script over"
