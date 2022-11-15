param prefix string
param location string = resourceGroup().location
param hubVnetName string
param networkRules array = []

@description('By default, Azure Firewall will not SNAT RFC 1918 private addresses. Use this field to remove this behavior with a comma-delmimited list of CIDR blocks.')
param privateTrafficPrefixes string = ''
param fireWallSubnetName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${prefix}-azfw-ip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource fwl 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: '${prefix}-azfw'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}-azfw-ipconf'
        properties: {
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', hubVnetName, fireWallSubnetName)
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkRuleCollections: ( (!empty(networkRules)) ? networkRules : null )
    additionalProperties: {
      'Network.SNAT.PrivateRanges': ( (!empty(privateTrafficPrefixes)) ? privateTrafficPrefixes : 'IANAPrivateRanges' )
    }
  }
}

output privateIp string = fwl.properties.ipConfigurations[0].properties.privateIPAddress
