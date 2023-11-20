param name string
param location string = resourceGroup().location
param subnetId string
param publicIpId string

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
            id: publicIpId
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
