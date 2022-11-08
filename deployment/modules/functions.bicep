param location string
param resourcePrefix string
param storageSkuName string
param storageAccountNameSuffix string
param functionAppNameSuffix string
param timeStamp string
param zoneRedundant bool
param functionSubnetId string
param dockerImageAndTag string

// TODO: Design for networking limits.  Example, DNS zones

module storage 'storage.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-${functionAppNameSuffix}-storage'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    storageSkuName: storageSkuName
    storageAccountNameSuffix: storageAccountNameSuffix
  }
}

module asp 'appServicePlan.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-${functionAppNameSuffix}-asp'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    appNameSuffix: functionAppNameSuffix
    serverOS: 'Linux'
    zoneRedundant: zoneRedundant
    skuName: 'EP1'
    skuTier: 'ElasticPremium'
  }
}

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: '${resourcePrefix}-fa-${functionAppNameSuffix}'
  location: location
  kind: 'functionapp,linux,container'
  properties: {
    serverFarmId: asp.outputs.resourceId
    httpsOnly: true
    virtualNetworkSubnetId: functionSubnetId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageAndTag}'
      vnetRouteAllEnabled: true
    }
  }

  dependsOn: [
    storage
  ]
}
