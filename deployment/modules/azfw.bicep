param prefix string
param actionGroupId string
param desktopSubnetCidr string
param devopsSubnetCidr string
param azPaasSubnetCidr string
param location string
param hubVnetName string

resource publicIp 'Microsoft.Network/publicIPAddresses@2020-06-01' = {
  name: '${prefix}-azfw-ip'
  location: location
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
  }
  sku: {
    name: 'Standard'
  }
}

resource fwl 'Microsoft.Network/azureFirewalls@2020-06-01' = {
  name: '${prefix}-azfw'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${prefix}-azfw-ipconf'
        properties: {
          subnet: {
            id: resourceId(subscription().id, '${prefix}-network-rg', 'Microsoft.Network/virtualNetworks/subnets', hubVnetName, 'AzureFilrewallSubnet')
          }
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkRuleCollections: [
      {
        name: 'test-collection'
        properties: {
          action: {
            type: 'Allow'
          }
          priority: 100
          rules: [
            {
              description: 'Allow outbound web traffic for desktop subnet'
              name: 'desktop-outbound-all'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                desktopSubnetCidr
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
              description: 'Allow SQL and SSL from desktop to app subnet'
              name: 'desktop-app-admin'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                desktopSubnetCidr
              ]
              destinationAddresses: [
                azPaasSubnetCidr
              ]
              destinationPorts: [
                '1433'
                '443'
              ]
            }
            {
              description: 'Allow outbound web traffic for devops subnet'
              name: 'devops-outbound-all'
              protocols: [
                'TCP'
              ]
              sourceAddresses: [
                devopsSubnetCidr
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

// alerts
resource firewallHealth 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'firewallHealth'
  location: 'global'
  properties: {
    description: 'Your firewall health is degraded'
    severity: 3
    enabled: true
    scopes: [
      resourceId('Microsoft.Network/azureFirewalls', fwl.name)
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: 90
          name: 'Metric1'
          metricNamespace: 'Microsoft.Network/azureFirewalls'
          metricName: 'FirewallHealth'
          dimensions: [
            {
              name: 'Status'
              operator: 'Include'
              values: [
                'Healthy'
              ]
            }
          ]
          operator: 'LessThan'
          timeAggregation: 'Average'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Network/azureFirewalls'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource applicationRuleHitCount 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'applicationRuleHitCount'
  location: 'global'
  properties: {
    description: 'Your firewall application rule count'
    severity: 3
    enabled: true
    scopes: [
      resourceId('Microsoft.Network/azureFirewalls', fwl.name)
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: 10
          name: 'Metric3'
          metricNamespace: 'Microsoft.Network/azureFirewalls'
          metricName: 'ApplicationRuleHit'
          dimensions: [
            {
              name: 'Status'
              operator: 'Include'
              values: [
                'Healthy'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Network/azureFirewalls'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

resource networkRuleHitCount 'microsoft.insights/metricAlerts@2018-03-01' = {
  name: 'networkRuleHitCount'
  location: 'global'
  properties: {
    description: 'Your firewall network rule hit count alert'
    severity: 3
    enabled: true
    scopes: [
      resourceId('Microsoft.Network/azureFirewalls', fwl.name)
    ]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      allOf: [
        {
          threshold: 500
          name: 'Metric2'
          metricNamespace: 'Microsoft.Network/azureFirewalls'
          metricName: 'NetworkRuleHit'
          dimensions: [
            {
              name: 'Status'
              operator: 'Include'
              values: [
                'Healthy'
              ]
            }
          ]
          operator: 'GreaterThan'
          timeAggregation: 'Total'
          criterionType: 'StaticThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    autoMitigate: true
    targetResourceType: 'Microsoft.Network/azureFirewalls'
    targetResourceRegion: location
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
  }
}

output privateIp string = fwl.properties.ipConfigurations[0].properties.privateIPAddress
