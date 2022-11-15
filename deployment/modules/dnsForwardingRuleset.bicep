param name string
param location string = resourceGroup().location

@description('Outbound endpoint id')
param outEndpointId string

param forwardingRuleName string
param forwardinRuleDomainName string
param forwardingRuleTargetDnsServers array
// param targetDnsServierIpAddress string

resource ruleset 'Microsoft.Network/dnsForwardingRulesets@2022-07-01' = {
  name: name
  location: location
  properties: {
    dnsResolverOutboundEndpoints: [
      {
        id: outEndpointId
      }
    ]
  }
}

resource fwRules 'Microsoft.Network/dnsForwardingRulesets/forwardingRules@2022-07-01' = {
  name: forwardingRuleName
  parent: ruleset
  properties: {
    forwardingRuleState: 'Enabled'
    domainName: forwardinRuleDomainName
    targetDnsServers: forwardingRuleTargetDnsServers
  }
}

output ruleSetName string = ruleset.name
