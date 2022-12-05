param name string
param location string = resourceGroup().location
param vnetId string

@description('Name of the private dns resolver outbound endpoint')
param outboundEndpointName string

@description('name of the subnet that will be used for private resolver outbound endpoint')
param outboundSubnetName string

param resourceGroupNameNetwork string
param vnetName string

var subscriptionId = subscription().subscriptionId
var subnetId = resourceId(subscriptionId, resourceGroupNameNetwork, 'Microsoft.Network/virtualNetworks/subnets', vnetName, outboundSubnetName)

resource resolver 'Microsoft.Network/dnsResolvers@2022-07-01' = {
  name: name
  location: location
  properties: {
    virtualNetwork: {
      id: vnetId
    }
  }
}

resource outEndpoint 'Microsoft.Network/dnsResolvers/outboundEndpoints@2022-07-01' = {
  parent: resolver
  name: outboundEndpointName
  location: location
  properties: {
    subnet: {
      id: subnetId
    }
  }
}

output outboundEndpointId string = outEndpoint.id
