param name string
param subnetId string
param location string

resource bastionIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${name}-ip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: { name: 'Standard' }
}

resource bastion 'Microsoft.Network/bastionHosts@2020-06-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      { name: 'bastionConf', properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionIP.id
          }
        } }
    ]
  }
}
