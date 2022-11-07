param location string
param resourcePrefix string
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
  }
}

output storageAccountName string = finalStorageAccountName
