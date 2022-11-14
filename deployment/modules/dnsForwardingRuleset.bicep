param name string
param location string = resourceGroup().location

@description('List of outbound endpoint ids: id: [value]')
param outEndpointIds array

@description('List of vnet IDs that will be use the DNS forwarding. Format is name: vnetId:')
param vnetResolverLinks array

// @description('List of domains with forwarding data. Format is name: domainName: targetDns:[ ipaddress: port: ]')
// param forwardingRules array


param forwardingRuleName string
param forwardinRuleDomainName string
param forwardingRuleTargetDnsServers array

resource ruleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: name
  location: location
  properties: {
    dnsResolverOutboundEndpoints: outEndpointIds
  }
}

resource resolverLinks 'Microsoft.Network/dnsForwardingRulesets/virtualNetworkLinks@2022-07-01' = [for link in vnetResolverLinks: {
  parent: ruleset
  name: link.name
  properties: {
    virtualNetwork: {
      id: link.vnetId
    }
  }
}]

/* Results in an Internal Server Error
resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = [for rule in forwardingRules: {
  parent: ruleset
  name: rule.name
  properties: {
    forwardingRuleState: 'Enabled'
    domainName: rule.domainName
    targetDnsServers: rule.targetDns
  }
}]
*/

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  parent: ruleset
  name: forwardingRuleName
  properties: {
    forwardingRuleState: 'Enabled'
    domainName: forwardinRuleDomainName
    targetDnsServers: forwardingRuleTargetDnsServers

  }
}

