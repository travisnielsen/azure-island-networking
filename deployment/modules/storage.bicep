param functionAppName string
param location string
param resourcePrefix string
@description('Use: Standard_LRS')
param storageSkuName string
param targetSubnetId string

var storageAccountNameSuffix = toLower(functionAppName)
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
          id: targetSubnetId
          action: 'Allow'
        }
      ]
      ipRules: []
      defaultAction: 'Allow' //TODO: set this to 'Deny' in a post provision script, function app config cannot be provisioned if it's not Allow initially
    }
  }
}

output storageAccountName string = finalStorageAccountName
output connString string = 'DefaultEndpointsProtocol=https;AccountName=${storageAccount.name};AccountKey=${listKeys(storageAccount.id, storageAccount.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'
output id string = storageAccount.id
