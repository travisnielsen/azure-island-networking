param vnetName string
param vnetId string
param zoneName string
param autoRegistration bool

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2018-09-01' = {
  name: '${zoneName}/${vnetName}-link'
  location: 'global'
  properties: {
     registrationEnabled: autoRegistration
      virtualNetwork: {
        id: vnetId
      }
  }
}