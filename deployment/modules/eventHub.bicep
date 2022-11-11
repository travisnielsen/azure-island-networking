param eventHubNames array
param location string
param resourceGroupNameNetwork string
param resourcePrefix string
param timeStamp string
param vnetName string
param zoneRedundant bool

resource eventHubNameSpace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: '${resourcePrefix}-ehns'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    // publicNetworkAccess: 'Disabled' - This won't be available until 2022-01-01-preview goes GA
  }
  sku: {
    name: 'Premium'
    capacity: 1
  }
}

resource eventHubs 'Microsoft.EventHub/namespaces/eventhubs@2021-11-01' = [for eventHubName in eventHubNames: {
  name: eventHubName
  parent: eventHubNameSpace
  properties: {
    partitionCount: 1
  }
}]

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-ehns'
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-ehns'
    serviceResourceId: eventHubNameSpace.id
    dnsZoneName: 'privatelink.azurewebsites.net'
    resourceGroupNameNetwork: resourceGroupNameNetwork
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'namespace'
  }
}

output hostName string = '${eventHubNameSpace.name}.servicebus.windows.net'
