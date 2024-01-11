param name string
param subnetId string
param location string = resourceGroup().location

@allowed([
  'Developer'
  'Basic'
  'Standard'
])
param sku string = 'Basic'

resource bastionIP 'Microsoft.Network/publicIPAddresses@2020-06-01' = if (sku != 'Developer') {
  name: '${name}-ip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource bastion 'Microsoft.Network/bastionHosts@2023-06-01' = {
  name: name
  location: location
  sku: {
    name: sku
  }
  properties: {
    ipConfigurations: [
      { 
        name: 'bastionConf', properties: {
          subnet: {
            id: subnetId
          }
          publicIPAddress: {
            id: bastionIP.id
          }
        }
      }
    ]
  }

}
