param location string
param resourceGroupNameNetwork string
param resourcePrefix string
param timeStamp string
param vnetName string
var acrName = format('{0}acr', replace(resourcePrefix, '-', ''))

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name:'Premium'
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-acr'
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-acr'
    serviceResourceId: containerRegistry.id
    dnsZoneName: 'privatelink.azurecr.io'
    resourceGroupNameNetwork: resourceGroupNameNetwork
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'registry'
  }
}
