param name string
param securityRules array
param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: name
  location: location
  properties: {
    securityRules: securityRules
  }
}

output id string = nsg.id
output nsgName string = nsg.name
