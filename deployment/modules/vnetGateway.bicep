param name string
param location string = resourceGroup().location
param subnetId string

resource vnetGatewayIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${name}-ip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: { name: 'Standard' }
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2023-05-01' = {
  name: name
  location: location
  properties: {
    vpnType: 'RouteBased'
    enableBgp: false
    activeActive: false
    ipConfigurations: [
      {
        name: 'vpnGatewayIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: vnetGatewayIP.id
          }
          subnet: {
            id: subnetId
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw1'
      tier: 'VpnGw1'
    }
  }
}
