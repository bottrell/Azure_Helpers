param (
[string]$SUBSCRIPTION,
[string]$ENVIRONMENT,
[string]$OUTPUT_PATH = ".\Output.csv"
)

#List of resource types that do not need to be monitored
$RESOURCES_TYPES = @{
    "Microsoft.Web/sites" = "Function App";
    "Microsoft.Storage/storageAccounts" = "Storage Account";
    "Microsoft.OperationalInsights/workspaces" = "Log Analytics Workspace";
    "Microsoft.Insights/components" = "Application Insights";
    "Microsoft.KeyVault/vaults" = "Key Vault";
    "Microsoft.Sql/servers" = "Azure Synapse";
    "Microsoft.Sql/servers/databases" = "Azure Synapse";
    "Microsoft.DataFactory/factories" = "Azure Data Factory (v2)";
    "Microsoft.ServiceBus/namespaces" = "Service Bus Namespace";
    "Microsoft.DocumentDB/databaseAccounts" = "Azure Cosmos DB Account";
    "Microsoft.EventGrid/systemTopics" = "Event Grid System Topic";
    "Microsoft.Web/serverFarms" = "App Service Plan"
    "Microsoft.Cache" = "Redis Cache";
    "Microsoft.ManagedIdentity/userAssignedIdentities" = "Managed Identity";
    "Microsoft.Networks/virtualNetworks" = "Virtual Network";
}

function authenticate () {
    #authenticate to Azure and select the environment based off of the $environment parameter
    Connect-AzAccount
    Set-AzContext -subscription $SUBSCRIPTION
}

function export_to_csv ($data) {
    $data | Export-Csv -Path $OUTPUT_PATH -Force
}

function get_data () {
    Write-Host "Entering get_data()"
    #Need to iterate through all the Azure resources, determine which ones need to be exported, add them all to a custom powershell object, and then return an array of objects
    $formatted_data = @()
    $all_azure_resources = Get-AzResource

    foreach ($resource in $all_azure_resources) {
        if ($resource.Type -in $RESOURCES_TYPES.Keys) {
            Write-Host "Processing data"
            $export = format_data $resource
            #add to formatted_data
            $formatted_data += $export
        }
    }

    return $formatted_data
}

function format_data ($resource) {
    $resourceType = $RESOURCES_TYPES[$resource.ResourceType]
    $formatted_resource = [PSCustomObject]@{
        Full_Application_Name = "Real Time Costing and Reporting Engine"
        Application = "CoRE"
        Environment = $ENVIRONMENT
        Subscription = $SUBSCRIPTION
        Resource_Group = $resource.ResourceGroupName
        Type = $resourceType
        os = $null
        domain = $null
        Prod_Site = $resource.Location
        Country = "US"
        Business_Technical_Function = "CoRE_$resourceType"
        Technology = "Azure"
        Monitoring_Type = "Full Stack"
        Name = $resource.Name
    }

    return $formatted_resource
}

function main() {
    
    if ($ENVIRONMENT.ToLower() -contains "prod") {
        $SUBSCRIPTION = "CoRE Production"
        $ENVIRONMENT = "prod"
    } else {
        $SUBSCRIPTION = "CoRE NonProduction"
        if ($ENVIRONMENT.ToLower() -contains "cert") {
            $ENVIRONMENT = "cert"
        } else {
            $ENVIRONMENT = "int"
        }
    }

    authenticate

    $data = get_data
    
    export_to_csv $data

    Write-Host "Successfully processed csv and exported to .\Output.csv"
}

main