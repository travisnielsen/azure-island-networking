param location string
param queueNames array
param networkResourceGroupName string 
param dnsResourceGroupName string
param resourcePrefix string
param timeStamp string
param vnetName string
param zoneRedundant bool

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: '${resourcePrefix}-sbns'
  location: location
  sku: {
    name: 'Premium'
    capacity: 1
  }
  properties: {
    zoneRedundant: zoneRedundant
    // publicNetworkAccess: 'Disabled' - This won't be available until 2022-01-01-preview goes GA
  }
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = [for queueName in queueNames: {
  name: queueName
  parent: serviceBus
  properties: {
    requiresSession: true
    maxMessageSizeInKilobytes: 1024
    maxSizeInMegabytes: 10240
    maxDeliveryCount: 3
  }
}]

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-sbns'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-sbns'
    serviceResourceId: serviceBus.id
    dnsZoneName: 'privatelink.servicebus.windows.net'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'namespace'
  }
}

output hostName string = '${serviceBus.name}.servicebus.windows.net'
