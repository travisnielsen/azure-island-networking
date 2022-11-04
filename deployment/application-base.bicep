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

// Network Watcher
param networkWatcherName string = 'NetworkWatcher_${region}'

resource networkRg 'Microsoft.Resources/resourceGroups@2020-06-01' existing = {
  name: '${orgPrefix}-network-rg'
}

resource workloadArg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${orgPrefix}-${appPrefix}-rg'
  location: region
  tags: tags
}

// ISLAND VNET IP SETTINGS
param islandVnetAddressSpace string = '192.168.0.0/16'
param aksSubnetAddressPrefix string = '192.168.0.0/22'        // 1019 addresses - 192.168.0.0 - 192.168.4.0
param utilSubnetAddressPrefix string = '192.168.4.0/22'       // 1019 addresses - 192.168.4.0 - 192.168.8.0
param privateEndpointAddressPrefix string = '192.168.8.0/24'  // 251  addresses - 192.168.8.0 - 192.168.9.0
param ehProducerFaAddressPrefix string = '192.168.9.0/26'     // 61   addresses - 192.168.9.0 - 192.168.9.63
param ehConsumerFaAddressPrefix string = '192.168.9.64/26'    // 61   addresses - 192.168.9.0 - 192.168.9.127

module vnet 'modules/vnet.bicep' = {
  name: '${appPrefix}-vnet'
  scope: resourceGroup(networkRg.name)
  params: {
    vnetName: '${appPrefix}-vnet'
    location: region
    addressSpaces: [
      islandVnetAddressSpace
    ]
    subnets: [
      {
        name: 'aks'
        properties: {
          addressPrefix: aksSubnetAddressPrefix
          /* TODO - Need to figure out how to get this value
          routeTable: {
            id: routeId
          }
          */
          networkSecurityGroup: {
            id: aksIntegrationNsg.outputs.id
          }
        }
      }
      {
        name: 'util'
        properties: {
          addressPrefix: utilSubnetAddressPrefix
          /* TODO - Need to figure out how to get this value
          routeTable: {
            id: routeId
          }
          */
          networkSecurityGroup: {
            id: utilNsg.outputs.id
          }
        }
      }
      {
        name: 'privateEndpoints'
        properties: {
          addressPrefix: privateEndpointAddressPrefix
          /* TODO - Need to figure out how to get this value
          routeTable: {
            id: routeId
          }
          */
          networkSecurityGroup: {
            id: privateEndpointsNsg.outputs.id
          }
        }
      }
      {
        name: 'ehProducer'
        properties: {
          addressPrefix: ehProducerFaAddressPrefix
          /* TODO - Need to figure out how to get this value
          routeTable: {
            id: routeId
          }
          */
          networkSecurityGroup: {
            id: ehProducerNsg.outputs.id
          }
        }
      }
      {
        name: 'ehConsumer'
        properties: {
          addressPrefix: ehConsumerFaAddressPrefix
          /* TODO - Need to figure out how to get this value
          routeTable: {
            id: routeId
          }
          */
          networkSecurityGroup: {
            id: ehConsumerNsg.outputs.id
          }
        }
      }
    ]
  }
}

// NSG for AKS subnet
module aksIntegrationNsg 'modules/nsg.bicep' = {
  name: '${appPrefix}-app-aks'
  scope: resourceGroup(networkRg.name)
  params: {
    name: '${orgPrefix}-${appPrefix}-app-aks'
    location: region
    networkWatcherName: networkWatcherName
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
    name: '${orgPrefix}-${appPrefix}-app-util'
    location: region
    networkWatcherName: networkWatcherName
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
    name: '${orgPrefix}-${appPrefix}-app-pe'
    location: region
    networkWatcherName: networkWatcherName
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
    name: '${orgPrefix}-${appPrefix}-app-ehProducer'
    location: region
    networkWatcherName: networkWatcherName
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
    name: '${orgPrefix}-${appPrefix}-app-ehConsumer'
    location: region
    networkWatcherName: networkWatcherName
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
