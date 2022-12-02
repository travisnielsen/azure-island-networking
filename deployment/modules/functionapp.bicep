param dockerImageAndTag string
param functionAppNameSuffix string
param functionSpecificAppSettings array
param functionSubnetId string
param location string
param resourceGroupNameNetwork string
param resourcePrefix string
param storageSkuName string
param tags object
param timeStamp string
param vnetName string
param zoneRedundant bool

var functionAppName = '${resourcePrefix}-fa-${functionAppNameSuffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourcePrefix}-ai'
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: format('{0}cr', replace(resourcePrefix, '-', ''))
}

module storage 'storage.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-${functionAppNameSuffix}-storage'
  params: {
    functionAppName: functionAppNameSuffix
    location: location
    resourcePrefix: resourcePrefix
    storageSkuName: storageSkuName
    targetSubnetId: functionSubnetId
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

var baseAppSettings = [
  {
    name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
    value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
  }
  {
    name: 'AzureWebJobsStorage__accountName'
    value: storage.outputs.storageAccountName
  }
  {
    name: 'FUNCTIONS_EXTENSION_VERSION'
    value: '~4'
  }
  {
    name: 'FUNCTIONS_WORKER_RUNTIME'
    value: 'dotnet'
  }
  {
    name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
    value: storage.outputs.connString
  }
  {
    name: 'WEBSITE_CONTENTSHARE'
    value: '${toLower(functionAppName)}-${substring(uniqueString(functionAppName), 0, 4)}'
  }
  {
    name: 'DOCKER_REGISTRY_SERVER_URL'
    value: 'https://${containerRegistry.name}.azurecr.io'
  }
  {
    name: 'DOCKER_ENABLE_CI'
    value: 'true'
  }
  {
    name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
    value: 'false'
  }
]

resource functionApp 'Microsoft.Web/sites@2021-03-01' = {
  name: functionAppName
  location: location
  kind: 'functionapp,linux,container'
  properties: {
    serverFarmId: asp.outputs.resourceId
    httpsOnly: true
    virtualNetworkSubnetId: functionSubnetId
    siteConfig: {
      linuxFxVersion: 'DOCKER|${dockerImageAndTag}'
      vnetRouteAllEnabled: true
      appSettings: concat(baseAppSettings, functionSpecificAppSettings)
    }
  }
  tags: tags

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
