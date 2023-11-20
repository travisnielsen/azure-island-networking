param location string
param resourceName string
param publicIpAddressSku string = 'Basic'
param publicIpAddressType string = 'Dynamic'

resource publicIpAddress 'Microsoft.Network/publicIPAddresses@2023-05-01' = {
  name: resourceName
  location: location
  sku: {
    name: publicIpAddressSku
  }
  properties: {
    publicIPAllocationMethod: publicIpAddressType
  }
}

output id string = publicIpAddress.id
