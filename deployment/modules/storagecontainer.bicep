param storageAccountName string
param storageContainerName string

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccountName}/default/${storageContainerName}'
}