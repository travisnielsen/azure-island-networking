param timeStamp string = utcNow('yyyyMMddHHmm')
param appPrefix string
param regionCode string
//param storageSkuName string
param location string = resourceGroup().location
param zoneRedundant bool = false
//param tenantId string

var resourcePrefix = '${appPrefix}-${regionCode}'


var functionApps = [
  {
    functionAppNameSuffix: 'ehConsumer'
    storageAccountNameSuffix: 'ehconsumer'
    dockerImageAndTag: 'cdcehconsumer:latest'
  }
  {
    functionAppNameSuffix: 'sbConsumer'
    storageAccountNameSuffix: 'sbconsumer'
    dockerImageAndTag: 'cdcsbconsumer:latest'
  }
  {
    functionAppNameSuffix: 'ehProducer'
    storageAccountNameSuffix: 'ehproducer'
    dockerImageAndTag: 'cdcehproducer:latest'
  }
]

var webApps = [
  {
    appServiceNameSuffix: 'weather'
    dockerImageAndTag: 'cdcgenericmicroserviceapi:latest'
  }
]

var entities = [
  'poc.customers.addresses'
]

// TODO - Refactor to parameterize vnet name
// TODO - This is all jacked up around managed identities
var aksSubnetId = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${appPrefix}-network-rg/providers/Microsoft.Network/virtualNetworks/${appPrefix}-workload-a/subnets/aks'
module aks 'modules/aks.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-aks'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    subnetId: aksSubnetId
  }
}

var tenantId = subscription().tenantId
module keyVault 'Modules/keyVault.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-kv'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    tenantId: tenantId
  }
}
