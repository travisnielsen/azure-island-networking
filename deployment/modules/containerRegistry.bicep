param location string
param networkResourceGroupName string
param dnsResourceGroupName string
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
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-acr'
    serviceResourceId: containerRegistry.id
    dnsZoneName: 'privatelink.azurecr.io'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'registry'
  }
}
