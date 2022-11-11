param dockerImageAndTag string
param functionAppNameSuffix string
param functionSubnetId string
param location string
param resourceGroupNameNetwork string
param resourcePrefix string
param storageSkuName string
param storageAccountNameSuffix string
param timeStamp string
param vnetName string
param zoneRedundant bool

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

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-${functionAppNameSuffix}'
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-${functionAppNameSuffix}'
    serviceResourceId: functionApp.id
    dnsZoneName: 'privatelink.azurewebsites.net'
    resourceGroupNameNetwork: resourceGroupNameNetwork
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'sites'
  }
}
