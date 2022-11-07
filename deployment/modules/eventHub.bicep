param resourcePrefix string
param location string
param eventHubNames array
param zoneRedundant bool

resource eventHubNameSpace 'Microsoft.EventHub/namespaces@2021-11-01' = {
  name: '${resourcePrefix}-ehns'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
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

output hostName string = '${eventHubNameSpace.name}.servicebus.windows.net'
