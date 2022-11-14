targetScope = 'subscription'

@allowed([
  'eastus'
  'eastus2'
  'northcentralus'
  'centralus'
  'westus'
  'westus2'
  'westus3'
])
param region string
param orgPrefix string
param appPrefix string
param tags object = {
  project: 'AzSecurePaaS'
  component: 'core'
}

@maxLength(16)
@description('The full prefix is the combination of the org prefix and app prefix and cannot exceed 16 characters in order to avoid deployment failures with certain PaaS resources such as storage or key vault')
param fullPrefix string = '${orgPrefix}-${appPrefix}'

resource networkRg 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: '${orgPrefix}-network'
}

resource workloadRg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: fullPrefix
  location: region
  tags: tags
}

resource bridgeVnet 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: '${orgPrefix}-bridge'
  scope: resourceGroup(networkRg.name)
}

resource hubAzFw 'Microsoft.Network/azureFirewalls@2022-05-01' existing = {
  name: '${orgPrefix}-hub-azfw'
  scope: resourceGroup(networkRg.name)
}

// ISLAND VNET IP SETTINGS
param islandVnetAddressSpace string = '192.168.0.0/16'
param aksSubnetAddressPrefix string = '192.168.0.0/22'          // 1019 addresses - 192.168.0.0 - 192.168.4.0
param utilSubnetAddressPrefix string = '192.168.4.0/22'         // 1019 addresses - 192.168.4.0 - 192.168.8.0
param privateEndpointAddressPrefix string = '192.168.8.0/24'    // 251  addresses - 192.168.8.0 - 192.168.9.0
param ehProducerFaAddressPrefix string = '192.168.9.0/26'       // 61   addresses - 192.168.9.0 - 192.168.9.63
param ehConsumerFaAddressPrefix string = '192.168.9.64/26'      // 61   addresses - 192.168.9.64 - 192.168.9.127
param sbConsumerFaAddressPrefix string = '192.168.9.128/26'      // 61   addresses - 192.168.9.128 - 192.168.9.192

module vnet 'modules/vnet.bicep' = {
  name: '${appPrefix}-vnet'
  scope: resourceGroup(networkRg.name)
  params: {
    vnetName: fullPrefix
    location: region
    addressSpaces: [
      islandVnetAddressSpace
    ]
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: aksIntegrationNsg.outputs.id
          }
        }
      }
      {
        name: 'util'
        properties: {
          addressPrefix: utilSubnetAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: utilNsg.outputs.id
          }
        }
      }
      {
        name: 'privateEndpoints'
        properties: {
          addressPrefix: privateEndpointAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: privateEndpointsNsg.outputs.id
          }
        }
      }
      {
        name: 'ehProducer'
        properties: {
          addressPrefix: ehProducerFaAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: ehProducerNsg.outputs.id
          }
          delegations: [
            {
              name: '${appPrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'ehConsumer'
        properties: {
          addressPrefix: ehConsumerFaAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: ehConsumerNsg.outputs.id
          }
          delegations: [
            {
              name: '${appPrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
      {
        name: 'sbConsumer'
        properties: {
          addressPrefix: sbConsumerFaAddressPrefix
          routeTable: {
            id: route.outputs.id
          }
          networkSecurityGroup: {
            id: sbConsumerNsg.outputs.id
          }
          delegations: [
            {
              name: '${appPrefix}-asp-delegation-${substring(uniqueString(deployment().name), 0, 4)}'
              properties: {
                serviceName: 'Microsoft.Web/serverfarms'
              }
              type: 'Microsoft.Network/virtualNetworks/subnets/delegations'
            }
          ]
          serviceENdpoints: [
            {
              service: 'Microsoft.Storage'
            }
          ]
        }
      }
    ]
  }
}

module route 'modules/udr.bicep' = {
  name: '${appPrefix}-workload-udr'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-udr'
    location: region
    azFwlIp: hubAzFw.properties.ipConfigurations[0].properties.privateIPAddress
  }
}

// NSG for AKS subnet
module aksIntegrationNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-aks'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-aks'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for Util subnet
module utilNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-util'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-util'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for Private Endpoints subnet
module privateEndpointsNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-pe'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-pe'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for EH Producer Integration subnet
module ehProducerNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-ehProducer'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-ehProducer'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for EH Consumer Integration subnet
module ehConsumerNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-ehConsumer'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-ehConsumer'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for EH Consumer Integration subnet
module sbConsumerNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-sbConsumer'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${fullPrefix}-app-sbConsumer'
    location: region
    securityRules: [
      {
        name: 'deny-inbound-default'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

module vnetPeerIslandToBridge 'modules/peering.bicep' = {
  name: 'island-to-bridge-peering'
  scope: resourceGroup(networkRg.name)
  params: {
    localVnetName: vnet.outputs.name
    remoteVnetName: bridgeVnet.name
    remoteVnetId: bridgeVnet.id
  }
}

module vnetPeerBridgeToIsland 'modules/peering.bicep' = {
  name: 'bridge-to-island-peering'
  scope: resourceGroup(networkRg.name)
  params: {
    localVnetName: bridgeVnet.name
    remoteVnetName: vnet.outputs.name
    remoteVnetId: vnet.outputs.id
  }
}

module acrPullMi 'modules/managedIdentity.bicep' = {
  name: '${appPrefix}-mi-acrPull'
  scope: resourceGroup(workloadRg.name)
  params: {
    location: region
    resourcePrefix: fullPrefix
    role: 'acrPull'
    tags: tags
  }
}

// Link to VNET to the Private DNS resolver
module resolverLink 'modules/dnsResolverLink.bicep' = {
  name: 'dns-resolver-link'
  scope: resourceGroup(networkRg.name)
  params: {
    forwardingRulesetName: 'dns-forward-ruleset-contoso'
    linkName: '${vnet.outputs.name}-link'
    vnetId: vnet.outputs.id
  }
}
