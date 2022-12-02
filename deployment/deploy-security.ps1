Function DecoratedOutput {
    param(
        [Parameter (Mandatory = $true)] [String]$baseMessage,
        [Parameter (Mandatory = $false)] [String]$secondaryMessage
    )

    Write-Host "$(Get-Date -Format G): " -ForegroundColor Yellow -NoNewline

    if ($secondaryMessage) {
        Write-Host "$baseMessage " -NoNewLine
        Write-Host "$secondaryMessage" -ForegroundColor Green
    }
    else {
        Write-Host "$baseMessage"
    }    
}

$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$orgPrefix = $Args[1]
$appPrefix = $Args[2]
$subscriptionId = $Args[3]
$targetResourceGroup = "$orgPrefix-$appPrefix-workload"

switch ($location) {
    'eastus' {
        $regionCode = 'eus'
    }
    'eastus2' {
        $regionCode = 'eus2'
    }
    'centralus' {
        $regionCode = 'cus'
    }
    'westus' {
        $regionCode = 'wus'
    }
    'westus2' {
        $regionCode = 'wus2'
    }
    'westus3' {
        $regionCode = 'wus3'
    }
    'northcentralus' {
        $regionCode = 'ncus'
    }

    Default {
        throw "Invalid Target Location Specified"
    }
}

$functionApps = @(
    [PSCustomObject]@{
        AppNameSuffix     = 'fa-ehConsumer';
        StorageNameSuffix = 'ehconsumer';
    }
    [PSCustomObject]@{
        AppNameSuffix     = 'fa-sbConsumer';
        StorageNameSuffix = 'sbconsumer';
    }
    [PSCustomObject]@{
        AppNameSuffix     = 'fa-ehProducer';
        StorageNameSuffix = 'ehproducer';
    }
)

# Define variables for configuration and managed identity assignment
$appName = "$orgPrefix-$appPrefix"
$serviceBusName = "$appName-$regionCode-sbns"
$eventHubName = "$appName-$regionCode-ehns"
$cosmosAccountName = "$appName-$regionCode-acdb"
$aksName = "$appName-$regionCode-aks"
$containerRegistryName = $appName.ToString().ToLower().Replace("-", "") + "$regionCode" + "acr"
$kvName = "$appName-$regionCode-kv"
$acrPullIdentityName = "$appName-$regionCode-mi-acrPull"
$kvSecretsUserIdentityName = "$appName-$regionCode-mi-kvSecrets"


# See if we already have our custom CosmosDB role defition.  This will be used for managed identity access
$cosmosRoleId = ''
(az cosmosdb sql role definition list --resource-group $targetResourceGroup --account-name $cosmosAccountName) | ConvertFrom-Json | ForEach-Object {
    #This role name is defined in the cosmos.role.definition.json file, if you change it here, change it there as well
    if ('ReadWriteRole' -eq $_.roleName) {
        $cosmosRoleId = $_.id
    }
}

# If the custom role definition doesn't exist, create it
if ([string]::IsNullOrWhiteSpace($cosmosRoleId)) {
    $cosmosRoleId = (az cosmosdb sql role definition create --resource-group $targetResourceGroup --account-name $cosmosAccountName --body "@cosmos.role.definition.json" --query id --output tsv)
    DecoratedOutput "Created Custom Cosmos Read/Write Role"
} else {
    DecoratedOutput "Custom Cosmos Read/Write Role already exists"
}

# Create a user defined managed identity and assign the AcrPull role to it.  This identity will then be added to all the function apps so they can access the container registry via managed identity
$acrPullPrincipalId = (az identity create --name $acrPullIdentityName --resource-group $targetResourceGroup --location $location --query principalId --output tsv)
$acrPullRoleId = (az role definition list --name "AcrPull" --query [0].id --output tsv)
DecoratedOutput "Got AcrPull Role Id:" $acrPullRoleId
$acrPullRoleAssignment_output = (az role assignment create --assignee $acrPullPrincipalId --role $acrPullRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ContainerRegistry/registries/$containerRegistryName" --output tsv)
DecoratedOutput "Completed role assignment of acrPull to User Identity"

# Create a user defined managed identity and assign the Key Vault Secrets User role to it.  This identity will then be added to all the function apps so they can access Key Vault via managed identity
$kvSecretsPrincipalId = (az identity create --name $kvSecretsUserIdentityName --resource-group $targetResourceGroup --location $location --query principalId --output tsv)
$keyVaultSecretsRoleId = (az role definition list --name "Key Vault Secrets User" --query [0].id --output tsv)
DecoratedOutput "Got Key Vault Secrets User Role Id:" $keyVaultSecretsRoleId
$kvSecretRoleAssignment_output = (az role assignment create --assignee $kvSecretsPrincipalId --role $keyVaultSecretsRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.KeyVault/vaults/$kvName" --output tsv)
DecoratedOutput "Completed role assignment of Key Vault Secrets User to User Identity"

# Wire up ACR to AKS - TODO: UNCOMMENT THIS ONCE AKS IS PROVISIONED
#$aksUpdate_output = az aks update -n $aksName -g $targetResourceGroup --attach-acr $containerRegistryName
#DecoratedOutput "Wired up AKS to ACR"

# For each of the function apps we created...
$functionApps | ForEach-Object {
    $functionAppNameSuffix = $_.AppNameSuffix
    $storageAccountSuffix = $_.StorageNameSuffix
    $storageAccountPrefix = $appName.ToString().ToLower().Replace("-", "")
    $storageAccountName = ($storageAccountPrefix + $regionCode + "sa" + $storageAccountSuffix)
    
    # This is here to make sure we don't exceed the storage account name length restriction
    if ($storageAccountName.Length -gt 24) {
        $storageAccountName = $storageAccountName.Substring(0, 24)
    }

    # Add the AcrPull managed identity to the function app
    $appIdentityAssignOutput = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$regionCode-$functionAppNameSuffix" --identities "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$acrPullIdentityName"  --query principalId --output tsv)
    DecoratedOutput "Added AcrPull MI to Function App" $functionAppNameSuffix

    # Add the Key Vault managed identity to the function app
    $appIdentityAssignOutput = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$regionCode-$functionAppNameSuffix" --identities "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ManagedIdentity/userAssignedIdentities/$kvSecretsUserIdentityName"  --query principalId --output tsv)
    DecoratedOutput "Added Key Vault Secrets User MI to Function App" $functionAppNameSuffix

    # Create a system managed identity for the function app.  This will be used to access storage accounts, event hubs, and service bus via managed identity
    $functionAppIdentityId = (az functionapp identity assign --resource-group $targetResourceGroup --name "$appName-$regionCode-$functionAppNameSuffix" --query principalId --output tsv)
    DecoratedOutput "Created $functionAppNameSuffix identity:" $functionAppIdentityId

    if ([string]::IsNullOrWhiteSpace($storageAccountSuffix) -ne $true) {
        # Assign function app's system identity to the storage blob data owner role
        $storageBlobDataOwnerRoleId = (az role definition list --name "Storage Blob Data Owner" --query [0].id --output tsv)
        DecoratedOutput "Got Storage Blog Data Role Id:" $storageBlobDataOwnerRoleId
        $storageBlobRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $storageBlobDataOwnerRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.Storage/storageAccounts/$storageAccountName"
        DecoratedOutput "Completed role assignment of $functionAppNameSuffix to" $storageAccountName
    }

    # Assign function app's system identity to the service bus data owner role
    # The owner role needs to be assigned to the listener (instead of the receiver role) so that it can peek into the queue 
    # length for making scaling decisions
    $serviceBusDataSenderRoleId = (az role definition list --name "Azure Service Bus Data Owner" --query [0].id --output tsv)
    DecoratedOutput "Got Service Bus Data Sender Role Id:" $serviceBusDataSenderRoleId
    $serviceBusRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $serviceBusDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.ServiceBus/namespaces/$serviceBusName"
    DecoratedOutput "Completed sender role assignment of $functionAppNameSuffix to" $serviceBusName

    # Assign function app's system identity to the event hub data sender role
    $eventHubDataSenderRoleId = (az role definition list --name "Azure Event Hubs Data Sender" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Sender Role Id:" $eventHubDataSenderRoleId
    $eventHubDataSenderRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataSenderRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Sender role assignment of $functionAppNameSuffix to" $eventHubName

    # Assign function app's system identity to the service bus data receiver role
    $eventHubDataReceiverRoleId = (az role definition list --name "Azure Event Hubs Data Receiver" --query [0].id --output tsv)
    DecoratedOutput "Got Event Hub Data Receiver Role Id:" $eventHubDataReceiverRoleId
    $eventHubDataReceiverRoleAssignment_output = az role assignment create --assignee $functionAppIdentityId --role $eventHubDataReceiverRoleId --scope "/subscriptions/$subscriptionId/resourcegroups/$targetResourceGroup/providers/Microsoft.EventHub/namespaces/$eventHubName"
    DecoratedOutput "Completed Event Hub Receiver role assignment of $functionAppNameSuffix to" $eventHubName
    
    # Assign function app's system identity to the custom ComsosDB role that was created above
    $cosmosRoleAssiment_output = az cosmosdb sql role assignment create --account-name $cosmosAccountName --resource-group $targetResourceGroup --scope "/" --principal-id $functionAppIdentityId --role-definition-id $cosmosRoleId
    DecoratedOutput "Assigned Custom Cosmos Role to" $functionAppNameSuffix
}