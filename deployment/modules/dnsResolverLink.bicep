param linkName string
param vnetId string
param forwardingRulesetName string

resource dnsResolver 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' existing = {
   name: forwardingRulesetName
}

resource resolverLink 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = {
  name: linkName
  parent: dnsResolver
  properties: {
    virtualNetwork: {
       id: vnetId
    }
  }
}
