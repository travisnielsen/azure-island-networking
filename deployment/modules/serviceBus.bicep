param resourcePrefix string
param location string
param zoneRedundant bool
param queueNames array

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' = {
  name: '${resourcePrefix}-sbns'
  location: location
  sku: {
    name: 'Premium'
    capacity: 1
  }
  properties: {
    zoneRedundant: zoneRedundant
  }
}

resource queues 'Microsoft.ServiceBus/namespaces/queues@2021-11-01' = [for queueName in queueNames: {
  name: queueName
  parent: serviceBus
  properties: {
    requiresSession: true
    maxMessageSizeInKilobytes: 1024
    maxSizeInMegabytes: 10240
    maxDeliveryCount: 2000
  }
}]

/*
resource autoScaleSettings 'Microsoft.Insights/autoscalesettings@2015-04-01' = {
  name: '${serviceBus.name}-autoScaleSettings'
  location: location
  properties: {
    targetResourceUri: serviceBus.id
    enabled: true
    profiles: [
      {
        name: '${serviceBus.name}-autoScaleprofile'
        capacity: {
          minimum: '1'
          maximum: '16'
          default: '16'
        }
        rules: [
          {
            scaleAction: {
              direction: 'Increase'
              type: 'ServiceAllowedNextValue'
              value: '1'
              cooldown: 'PT5M'
            }
            metricTrigger:{
              metricName: 'NamespaceCpuUsage'
              metricNamespace: 'microsoft.servicebus/namespaces'
              metricResourceUri: serviceBus.id
              operator: 'GreaterThan'
              statistic: 'Average'
            }
          }
        ]
      }
    ]
  }
}
*/


output hostName string = '${serviceBus.name}.servicebus.windows.net'


/*

/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/microsoft.insights/autoscalesettings/cdc-poc-wus-sbns-Autoscale-741
{
    "location": "West US",
    "tags": {},
    "properties": {
        "name": "cdc-poc-wus-sbns-Autoscale-741",
        "enabled": true,
        "targetResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
        "profiles": [
            {
                "name": "Auto created scale condition",
                "capacity": {
                    "minimum": "1",
                    "maximum": "16",
                    "default": "16"
                },
                "rules": [
                    {
                        "scaleAction": {
                            "direction": "Increase",
                            "type": "ServiceAllowedNextValue",
                            "value": "1",
                            "cooldown": "PT5M"
                        },
                        "metricTrigger": {
                            "metricName": "NamespaceCpuUsage",
                            "metricNamespace": "microsoft.servicebus/namespaces",
                            "metricResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
                            "operator": "GreaterThan",
                            "statistic": "Average",
                            "threshold": 70,
                            "timeAggregation": "Maximum",
                            "timeGrain": "PT1M",
                            "timeWindow": "PT5M",
                            "Dimensions": [],
                            "dividePerInstance": false
                        }
                    },
                    {
                        "scaleAction": {
                            "direction": "Increase",
                            "type": "ServiceAllowedNextValue",
                            "value": "1",
                            "cooldown": "PT5M"
                        },
                        "metricTrigger": {
                            "metricName": "NamespaceMemoryUsage",
                            "metricNamespace": "microsoft.servicebus/namespaces",
                            "metricResourceUri": "/subscriptions/506cf09b-823b-4baa-9155-11e70406819b/resourceGroups/cdc-poc-wus-rg/providers/Microsoft.ServiceBus/namespaces/cdc-poc-wus-sbns",
                            "operator": "GreaterThan",
                            "statistic": "Average",
                            "threshold": 70,
                            "timeAggregation": "Maximum",
                            "timeGrain": "PT1M",
                            "timeWindow": "PT5M",
                            "Dimensions": [],
                            "dividePerInstance": false
                        }
                    }
                ]
            }
        ],
        "notifications": [],
        "targetResourceLocation": "West US"
    },

*/
