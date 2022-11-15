param location string
param resourcePrefix string
@description('Use: Standard_LRS')
param storageSkuName string
param storageAccountNameSuffix string
var storageResourcePrefix = format('{0}sa', replace(resourcePrefix, '-', ''))
var storageAccountName = '${storageResourcePrefix}${storageAccountNameSuffix}'
var finalStorageAccountName = length(storageAccountName) > 24 ? substring(storageAccountName, 0, 24) : storageAccountName

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: finalStorageAccountName
  location: location
  sku: {
    name: storageSkuName
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: '/subscriptions/7029af60-98ff-4083-96c0-695eba78c91b/resourceGroups/contoso-network/providers/Microsoft.Network/virtualNetworks/contoso-app1/subnets/ehProducer'
          action: 'Allow'
        }
      ]
      ipRules: []
      // defaultAction: 'Deny' TODO: set this in a post provision script
    }
  }
}

output storageAccountName string = finalStorageAccountName
output connString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
