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
param tags object = {
  project: 'AzIslandNetworking'
  component: 'core'
}

// DNS Server
// DevOps Build Server
param dnsVmAdminUserName string = 'dnsadmin'

@secure()
param dnsVmAdminPwd string

// HUB VNET IP SETTINGS
param hubVnetAddressSpace string = '10.10.0.0/20'
param hubFirewallSubnetAddressSpace string = '10.10.0.0/25'             // 123 addresses - 10.10.0.0 - 10.10.0.127
param hubDnsSubnetAddressSpace string = '10.10.0.128/25'                // 123 addresses - 10.10.0.128 - 10.10.1.255
param hubDnsResolverOutboundSubnetAddressSpace string = '10.10.1.0/26'  // 59 addresses - 10.10.1.0 - 10.10.1.63

// BRIDGE VNET IP SETTINGS
param bridgeVnetAddressSpace string = '10.10.16.0/20'
param bridgeFirewallSubnetAddressSpace string = '10.10.16.0/25'       // 123 addresses - 10.10.16.0 - 10.10.16.127
param bridgeBastionSubnetAddressSpace string = '10.10.16.128/25'      // 123 addresses - 10.10.16.128 - 10.10.0.255
param bridgePrivateLinkSubnetAddressSpace string = '10.10.17.0/25'    // 123 addresses - 10.10.17.0 - 10.10.17.127
param bridgeAppGatewaySubnetAddressSpace string = '10.10.17.128/25'   // 123 addresses - 10.10.17.128 - 10.10.17.255

// SPOKE VNET IP SETTINGS
param spokeVnetAddressSpace string = '10.10.32.0/20'
param spokeVnetVmAddressSpace string = '10.10.32.0/25'                // 123 addresses - 10.10.32.0 - 10.10.32.127
param spokeVnetPrivateLinkAddressSpace string = '10.10.32.128/25'     // 123 addresses - 10.10.32.128 - 10.10.32.255
param spokeVnetIntegrationSubnetAddressSpace string = '10.10.33.0/25' // 123 addresses - 10.10.33.0 - 10.10.33.127

resource netrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${orgPrefix}-network'
  location: region
  tags: tags
}

resource iaasrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${orgPrefix}-iaas'
  location: region
  tags: tags
}

resource devopsrg 'Microsoft.Resources/resourceGroups@2020-06-01' = {
  name: '${orgPrefix}-devops'
  location: region
  tags: tags
}

// Log Analytics
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'log-analytics'
  scope: resourceGroup(netrg.name)
  params: {
    location: region
    name: netrg.name
  }
}

// Storage for NSG flow logs
module nsgFlowLogStorage 'modules/storage.bicep' = {
  name: 'nsg-flowlog-storage'
  scope: resourceGroup(netrg.name)
  params: {
    location: region
    resourcePrefix: orgPrefix
    storageAccountNameSuffix: 'flowlogs'
    storageSkuName: 'Standard_LRS'
  }
}


module hubVnet 'modules/vnet.bicep' = {
  name: 'hub-vnet'
  scope: resourceGroup(netrg.name)
  params: {
    vnetName: '${orgPrefix}-hub'
    location: region
    addressSpaces: [ 
      hubVnetAddressSpace 
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: hubFirewallSubnetAddressSpace
        }
      }
      {
        name: 'dns'
        properties: {
          addressPrefix: hubDnsSubnetAddressSpace
          networkSecurityGroup: { 
            id: hubDnsNsg.outputs.id 
          }
          privateEndpointNetworkPolicies: 'Enabled'
          /*
          routeTable: {
            id: route.outputs.id
          }
          */
        }
      }
      {
        name: 'dns-resolver-outbound'
        properties: {
          addressPrefix: hubDnsResolverOutboundSubnetAddressSpace
          networkSecurityGroup: { 
            id: hubDnsNsg.outputs.id 
          }
          privateEndpointNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'dns-resolver'
              properties: { 
                serviceName: 'Microsoft.Network/dnsResolvers' 
              }
            }
          ]
        }
      }


    ]
  }
}

module bridgeVnet 'modules/vnet.bicep' = {
  name: 'bridge-vnet'
  scope: resourceGroup(netrg.name)
  params: {
    vnetName: '${orgPrefix}-bridge'
    location: region
    addressSpaces: [ 
      bridgeVnetAddressSpace 
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: bridgeFirewallSubnetAddressSpace
        }
      }
      {
        // NOTE: UDR not allowed in a Bastion subnet
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: bridgeBastionSubnetAddressSpace
          networkSecurityGroup: { 
            id: bastionNsg.outputs.id 
          }
        }
      }
      {
        name: 'privatelinks'
        properties: {
          addressPrefix: bridgePrivateLinkSubnetAddressSpace
          networkSecurityGroup: { 
            id: bridgePrivateLinkNsg.outputs.id 
          }
        }
      }
      {
        name: 'appgateways'
        properties: {
          addressPrefix: bridgeAppGatewaySubnetAddressSpace
          networkSecurityGroup: { 
            id: bridgeAppGatewayNsg.outputs.id 
          }
        }
      }
    ]
  }

}

module spokeVnet 'modules/vnet.bicep' = {
  name: 'spoke-vnet'
  scope: resourceGroup(netrg.name)
  params: {
    vnetName: '${orgPrefix}-spoke'
    location: region
    addressSpaces: [
      spokeVnetAddressSpace 
    ]
    subnets: [
      {
        name: 'iaas'
        properties: {
          addressPrefix: spokeVnetVmAddressSpace
          routeTable: { 
            id: route.outputs.id 
          }
          networkSecurityGroup: { 
            id: spokeVirtualMachinesNsg.outputs.id 
          }
        }
      }
      {
        name: 'privatelink'
        properties: {
          addressPrefix: spokeVnetPrivateLinkAddressSpace
          routeTable: { 
            id: route.outputs.id 
          }
          networkSecurityGroup: { 
            id: spokePrivateLinkNsg.outputs.id 
          }
          privateEndpointNetworkPolicies: 'Disabled'
        }
      }
      {
        name: 'funcintegration'
        properties: {
          addressPrefix: spokeVnetIntegrationSubnetAddressSpace
          delegations: [
            {
              name: 'delegation'
              properties: { 
                serviceName: 'Microsoft.Web/serverfarms' 
              }
            }
          ]
          privateEndpointNetworkPolicies: 'Enabled'
          routeTable: { 
            id: route.outputs.id 
          }
          networkSecurityGroup: { 
            id: spokeFuncIntegrationNsg.outputs.id 
          }
        }
      }
    ]
  }
}


// NSG for DNS subnet (Linux server running BIND)
module hubDnsNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-hub-dns'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${orgPrefix}-hub-dns'
    location: region
    securityRules: [
      {
        name: 'allow-bastion'
        properties: { 
          priority: 100 
          direction: 'Inbound'
          protocol: '*'
          access: 'Allow'
          sourceAddressPrefix: bridgeBastionSubnetAddressSpace
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [ 
            '22'
            '3389' 
          ] 
        } 
      }
      {
        name: 'allow-dns'
        properties: { 
          priority: 110
          direction: 'Inbound'
          protocol: '*'
          access: 'Allow'
          sourceAddressPrefixes: [
            bridgeBastionSubnetAddressSpace
            hubVnetAddressSpace
            spokeVnetAddressSpace
          ]
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [ 
            '53' 
          ] 
        } 
      }

      /* Internet egress will be forced through Azure Firewall. Deny at the NSG level supercedes UDR flow 
      {
        name: 'deny-internet'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
      */
    ]
  }
}

// NSG for Bastion subnet
module bastionNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-bridge-bastion'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    hubDnsNsg
  ]
  params: {
    name: '${orgPrefix}-bridge-bastion'
    location: region
    securityRules: [
      // SEE: https://docs.microsoft.com/en-us/azure/bastion/bastion-nsg#apply
      {
        name: 'bastion-ingress'
        properties: {
          priority: 100
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'bastion-gatewaymgr'
        properties: {
          priority: 120
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'GatewayManager'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'bastion-loadbalancer'
        properties: {
          priority: 140
          protocol: 'Tcp'
          access: 'Allow'
          direction: 'Inbound'
          sourceAddressPrefix: 'AzureLoadBalancer'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '443'
        }
      }
      {
        name: 'allow-ssh-rdp-vnet'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'allow-azure-dependencies'
        properties: {
          priority: 120
          protocol: '*'
          access: 'Allow'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'AzureCloud'
          destinationPortRange: '443'
        }
      }
      {
        name: 'deny-internet'
        properties: {
          priority: 140
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for Azure services configured with Private Link (bridge)
module bridgePrivateLinkNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-bridge-privatelinks'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${orgPrefix}-bridge-privatelinks'
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
      {
        name: 'deny-internet'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for App Gateway subnet (private build servers)
module bridgeAppGatewayNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-bridge-appgw'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    bastionNsg
  ]
  params: {
    name: '${orgPrefix}-bridge-appgw'
    location: region
    securityRules: [
      {
        name: 'deny-internet'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}

// NSG for Azure Functions subnet
module spokeVirtualMachinesNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-spoke-iaas'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${orgPrefix}-spoke-iaas'
    location: region
    securityRules: [
      {
        name: 'allow-inbound-ssh'
        properties: {
          priority: 100
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: hubVnetAddressSpace
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '22'
          ]
        }
      }   
      {
        name: 'allow-inbound-web'
        properties: {
          priority: 110
          protocol: '*'
          access: 'Deny'
          direction: 'Inbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }

      // Internet egress will be forced through Azure Fireall. Deny at the NSG level supercedes UDR flow
    ]
  }
}

// NSG for Azure Functions subnet
module spokeFuncIntegrationNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-spoke-functions'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${orgPrefix}-spoke-functions'
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

      /* Internet egress will be forced through Azure Fireall. Deny at the NSG level supercedes UDR flow
      {
        name: 'deny-internet'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: 'Internet'
          sourcePortRange: '*'
          destinationAddressPrefix: '*'
          destinationPortRange: '*'
        }
      }
      */
    ]
  }
}

// NSG for Azure services configured with Private Link (spoke)
module spokePrivateLinkNsg 'modules/nsg.bicep' = {
  name: '${orgPrefix}-spoke-privatelinks'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    spokeFuncIntegrationNsg
  ]
  params: {
    name: '${orgPrefix}-spoke-privatelinks'
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
      {
        name: 'deny-internet'
        properties: {
          priority: 1000
          protocol: '*'
          access: 'Deny'
          direction: 'Outbound'
          sourceAddressPrefix: '*'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          destinationPortRange: '*'
        }
      }
    ]
  }
}


// Azure Fireall - HUB
module hubAzFw 'modules/azfw.bicep' = {
  name: 'hub-azfw'
  scope: resourceGroup(netrg.name)
  params: {
    prefix: '${orgPrefix}-hub'
    fireWallSubnetName: 'AzureFirewallSubnet'
    location: region
    hubVnetName: hubVnet.outputs.name
    networkRules: [
      {
        name: 'core-rules'
        properties: {
          action: { type: 'Allow' }
          priority: 100
          rules: [
            {
              description: 'Allow outbound web traffic'
              name: 'allow-outbound-all'
              protocols: [ 
                'TCP' 
              ]
              sourceAddresses: [
                spokeVnetIntegrationSubnetAddressSpace
                spokeVnetVmAddressSpace
                hubDnsSubnetAddressSpace
              ]
              destinationAddresses: [ 
                '*'
              ]
              destinationPorts: [ 
                '80'
                '443'
              ]
            }
          ]
        }
      }
    ]
  }
}

// Azure Firewall - BRIDGE
module bridgeAzFw 'modules/azfw.bicep' = {
  name: 'bridge-azfw'
  scope: resourceGroup(netrg.name)
  params: {
    prefix: '${orgPrefix}-bridge'
    fireWallSubnetName: 'AzureFirewallSubnet'
    location: region
    hubVnetName: bridgeVnet.outputs.name
    networkRules: [
      {
        name: 'island-networking-config'
        properties: {
          action: { type: 'Allow' }
          priority: 100
          rules: [
            {
              description: 'Allow outbound web traffic'
              name: 'allow-outbound-all'
              protocols: [ 
                'TCP' 
              ]
              sourceAddresses: [
                '192.160.0.0/16'
              ]
              destinationAddresses: [ 
                '*'
              ]
              destinationPorts: [ 
                '80'
                '443'
              ]
            }
            {
              description: 'Allow Island to Corp'
              name: 'island-to-corp'
              protocols: [ 
                'TCP'
              ]
              sourceAddresses: [
                '192.160.0.0/16'
              ]
              destinationAddresses: [ 
                '10.0.0.0/8'
              ]
              destinationPorts: [ 
                '*'
              ]
            }
          ]
        }
      }
    ]
  }
}


// VNET peering
module HubToSpokePeering 'modules/peering.bicep' = {
  name: 'hub-to-spoke-peering'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: hubVnet.outputs.name
    remoteVnetName: 'spoke'
    remoteVnetId: spokeVnet.outputs.id
  }
}

// VNET peering
module SpokeToHubPeering 'modules/peering.bicep' = {
  name: 'spoke-to-hub-peering'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: spokeVnet.outputs.name
    remoteVnetName: 'hub'
    remoteVnetId: hubVnet.outputs.id
  }
}


module HubToBridgePeering 'modules/peering.bicep' = {
  name: 'hub-to-bridge-peering'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: hubVnet.outputs.name
    remoteVnetName: 'bridge'
    remoteVnetId: bridgeVnet.outputs.id
  }
}

module BridgeToHubPeering 'modules/peering.bicep' = {
  name: 'bridge-to-hub-peering'
  scope: resourceGroup(netrg.name)
  params: {
    localVnetName: bridgeVnet.outputs.name
    remoteVnetName: 'hub'
    remoteVnetId: hubVnet.outputs.id
  }
}

// User Defined Route (force egress traffic through hub firewall)
module route 'modules/udr.bicep' = {
  name: 'core-udr'
  scope: resourceGroup(netrg.name)
  params: {
    name: '${orgPrefix}-udr'
    location: region
    azFwlIp: hubAzFw.outputs.privateIp
  }
}

// Bastion
module bastion 'modules/bastion.bicep' = {
  name: 'bridge-bastion'
  scope: resourceGroup(netrg.name)
  params: {
    name: uniqueString(netrg.id)
    location: region
    subnetId: '${bridgeVnet.outputs.id}/subnets/AzureBastionSubnet'
  }
}

// Private DNS zone for Azure Web Sites (Functions and Web Apps)
module privateZoneAzureWebsites 'modules/dnszoneprivate.bicep' = {
  name: 'dns-private-azurewebsites'
  scope: resourceGroup(netrg.name)
  params: {
    zoneName: 'privatelink.azurewebsites.net'
  }
}

// Link the spoke VNet to the privatelink.azurewebsites.net private zone
module spokeVnetAzureWebsitesZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-azurewebsites-spokevnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureWebsites
  ]
  params: {
    vnetName: spokeVnet.outputs.name
    vnetId: spokeVnet.outputs.id
    zoneName: 'privatelink.azurewebsites.net'
    autoRegistration: false
  }
}

// Link the hub VNet to the privatelink.azurewebsites.net private zone
module hubVnetAzureWebsitesZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-azurewebsites-hubvnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureWebsites
  ]
  params: {
    vnetName: hubVnet.outputs.name
    vnetId: hubVnet.outputs.id
    zoneName: 'privatelink.azurewebsites.net'
    autoRegistration: false
  }
}

// Private DNS zone for Azure Blob Storage (ADLS)
module privateZoneAzureBlobStorage 'modules/dnszoneprivate.bicep' = {
  name: 'dns-private-storage-blob'
  scope: resourceGroup(netrg.name)
  params: {
    zoneName: 'privatelink.blob.${environment().suffixes.storage}'
  }
}

// Link the spoke VNet to the privatelink.blob.core.windows.net private zone
module spokeVnetAzureBlobStorageZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-blobstorage-spokevnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureBlobStorage
  ]
  params: {
    vnetName: spokeVnet.outputs.name
    vnetId: spokeVnet.outputs.id
    zoneName: 'privatelink.blob.${environment().suffixes.storage}'
    autoRegistration: false
  }
}

// Link the hub VNet to the privatelink.blob.core.windows.net private zone
module hubVnetAzureBlobStorageZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-blobstorage-hubvnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureBlobStorage
  ]
  params: {
    vnetName: hubVnet.outputs.name
    vnetId: hubVnet.outputs.id
    zoneName: 'privatelink.blob.${environment().suffixes.storage}'
    autoRegistration: false
  }
}

// Private DNS for Azure Data Factory
module privateZoneAzureDataFactory 'modules/dnszoneprivate.bicep' = {
  name: 'dns-private-datafactory'
  scope: resourceGroup(netrg.name)
  params: {
    zoneName: 'privatelink.datafactory.azure.net'
  }
}

// Link the spoke VNet to the privatelink.datafactory.azure.net private zone
module spokeVnetAzureDataFactoryZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-datafactory-spokevnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureDataFactory
  ]
  params: {
    vnetName: spokeVnet.outputs.name
    vnetId: spokeVnet.outputs.id
    zoneName: 'privatelink.datafactory.azure.net'
    autoRegistration: false
  }
}

// Link the hub VNet to the privatelink.datafactory.azure.net private zone
module hubVnetAzureDataFactoryZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-datafactory-hubvnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzureDataFactory
  ]
  params: {
    vnetName: hubVnet.outputs.name
    vnetId: hubVnet.outputs.id
    zoneName: 'privatelink.datafactory.azure.net'
    autoRegistration: false
  }
}

// Private DNS zone for SQL
module privateZoneSql 'modules/dnszoneprivate.bicep' = {
  name: 'dns-private-sql'
  scope: resourceGroup(netrg.name)
  params: {
    zoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
  }
}

// Link the spoke VNet to the privatelink.database.windows.net private zone
module spokeVnetSqlZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-sql-spokevnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneSql
  ]
  params: {
    vnetName: spokeVnet.outputs.name
    vnetId: spokeVnet.outputs.id
    zoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    autoRegistration: false
  }
}

// Link the hub VNet to the privatelink.database.windows.net private zone
module hubVnetSqlZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-sql-hubvnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneSql
  ]
  params: {
    vnetName: hubVnet.outputs.name
    vnetId: hubVnet.outputs.id
    zoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    autoRegistration: false
  }
}

// Private DNS zone for other Azure services
module privateZoneAzure 'modules/dnszoneprivate.bicep' = {
  name: 'dns-private-azure'
  scope: resourceGroup(netrg.name)
  params: {
    zoneName: 'privatelink.azure.com'
  }
}

// Link the spoke VNet to the privatelink.azure.com private zone
// NOTE: See: https://stackoverflow.com/questions/64725413/azure-bastion-and-private-link-in-the-same-virtual-network-access-to-virtual-ma
// Must add CNAME record for 'management.privatelink.azure.com' that points to 'arm-frontdoor-prod.trafficmanager.net'
module frontdoorcname 'modules/dnscname.bicep' = {
  name: 'frontdoor-cname'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzure
  ]
  params: {
    appName: 'management'
    dnsZone: 'privatelink.azure.com'
    alias: 'arm-frontdoor-prod.${environment().suffixes.azureFrontDoorEndpointSuffix}'
  }
}

module spokeVnetAzureZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-azure-spokevnet'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzure
  ]
  params: {
    vnetName: spokeVnet.outputs.name
    vnetId: spokeVnet.outputs.id
    zoneName: 'privatelink.azure.com'
    autoRegistration: false
  }
}

module hubVnetAzureZoneLink 'modules/dnszonelink.bicep' = {
  name: 'dns-link-azure-hub'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    privateZoneAzure
  ]
  params: {
    vnetName: hubVnet.outputs.name
    vnetId: hubVnet.outputs.id
    zoneName: 'privatelink.azure.com'
    autoRegistration: false
  }
}


// TODO: THIS IS A HACK - need to find a better way to apply the UDR to the DNS server subnet
module applyUdrsForHub 'modules/vnet.bicep' = {
  name: 'hub-vnet-update'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    hubVnet
  ]
  params: {
    vnetName: '${orgPrefix}-hub'
    location: region
    addressSpaces: [ 
      hubVnetAddressSpace 
    ]
    subnets: [
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: hubFirewallSubnetAddressSpace
        }
      }
      {
        name: 'dns'
        properties: {
          addressPrefix: hubDnsSubnetAddressSpace
          networkSecurityGroup: { 
            id: hubDnsNsg.outputs.id 
          }
          privateEndpointNetworkPolicies: 'Enabled'
          routeTable: {
            id: route.outputs.id
          }
        }
      }
      {
        name: 'dns-resolver-outbound'
        properties: {
          addressPrefix: hubDnsResolverOutboundSubnetAddressSpace
          networkSecurityGroup: { 
            id: hubDnsNsg.outputs.id 
          }
          privateEndpointNetworkPolicies: 'Enabled'
          delegations: [
            {
              name: 'dns-resolver'
              properties: { 
                serviceName: 'Microsoft.Network/dnsResolvers' 
              }
            }
          ]
        }
      }
    ]
  }
}


// DNS server for contoso.com
module dnsServer 'modules/virtualMachine.bicep' = {
  name: 'dns-server-consoso-com'
  scope: resourceGroup(iaasrg.name)
  dependsOn: [
    hubVnet
  ]
  params: {
    adminUserName: dnsVmAdminUserName
    adminPassword: dnsVmAdminPwd
    networkResourceGroupName: netrg.name
    location: region
    vnetName: hubVnet.outputs.name
    subnetName: 'dns'
    os: 'linux'
    vmName: 'contoso-dns01'
    vmSize: 'Standard_B2ms'
    initScriptBase64: loadFileAsBase64('dnsserver.yml')
  }
}


// Private DNS Resolver
module dnsResolver 'modules/dnsResolver.bicep' = {
  name: 'dns-resolver'
  scope: resourceGroup(netrg.name)
  dependsOn: [
    applyUdrsForHub
  ]
  params: {
    name: 'dns-resolver-hub'
    location: region
    vnetId: hubVnet.outputs.id
    outboundEndpointName: 'dns-resolver-hub-outbound'
    outboundSubnetName: 'dns-resolver-outbound'
  }
}

// Forwarding ruleset for contoso.com
module contosoForwardingRuleset 'modules/dnsForwardingRuleset.bicep' = {
  name: 'dns-forward-ruleset-contoso'
  scope: resourceGroup(netrg.name)
  params: {
    name: 'dns-forward-ruleset'
    location: region
    outEndpointIds: [
      dnsResolver.outputs.outboundEndpointId
    ]
    vnetResolverLinks: [
      {
        name: hubVnet.outputs.name
        vnetId: hubVnet.outputs.id
      }
      {
        name: spokeVnet.outputs.name
        vnetId: spokeVnet.outputs.id
      }
    ]
    forwardingRuleName: 'contoso-com'
    forwardinRuleDomainName: 'contoso.com.'
    forwardingRuleTargetDnsServers: [
      {
        ipaddress: '10.10.0.132'
        port: 53
      }
    ]
  }
}



 