param privateEndpointName string
param resourceGroupNameNetwork string
param vnetName string
param subnetName string
param serviceResourceId string
param dnsZoneName string
param groupId string

var subscriptionId = subscription().subscriptionId
var subnetId = resourceId(subscriptionId, resourceGroupNameNetwork, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var dnsZoneId = resourceId(subscriptionId, resourceGroupNameNetwork, 'Microsoft.Network/privateDnsZones', dnsZoneName )

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: resourceGroup().location
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: serviceResourceId
          groupIds: [
            groupId
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneConfig 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2020-06-01' = {
  name: '${privateEndpointName}/dnsgroupname'
  dependsOn: [
    privateEndpoint
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: dnsZoneId
        }
      }
    ]
  }
}

output id string = privateEndpoint.id