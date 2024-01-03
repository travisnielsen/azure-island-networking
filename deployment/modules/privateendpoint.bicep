param privateEndpointName string
param networkResourceGroupName string
param dnsResourceGroupName string
param vnetName string
param subnetName string
param serviceResourceId string
param dnsZoneName string
param groupId string
param location string

var subscriptionId = subscription().subscriptionId
var subnetId = resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
var dnsZoneId = resourceId(subscriptionId, dnsResourceGroupName, 'Microsoft.Network/privateDnsZones', dnsZoneName )

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2020-06-01' = {
  name: privateEndpointName
  location: location
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
  name: 'dnsgroupname'
  parent: privateEndpoint
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
