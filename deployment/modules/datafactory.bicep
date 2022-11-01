param adfName string
param actionGroupId string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: adfName
  location: resourceGroup().location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    /*
    repoConfiguration: {
      type: 'FactoryVSTSConfiguration'
      accountName: ''
      projectName: ''
      repositoryName: ''
      collaborationBranch: ''
      rootFolder: ''
    }
    */
  }
}

resource whenadfactivityfailed 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'whenadfactivityfailed'
  location: 'global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    autoMitigate: true
    criteria: {
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
          metricName: 'ActivityFailedRuns'
          metricNamespace: 'Microsoft.DataFactory/factories'
          name: 'Metric1'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Total'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    description: 'send alert when adf activity failed'
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      resourceId('Microsoft.DataFactory/factories', dataFactory.name)
    ]
    severity: 4
    targetResourceType: 'Microsoft.DataFactory/factories'
    windowSize: 'PT1M'
  }
  dependsOn: [
    dataFactory
  ]
}

resource whenadfpipelinefailed 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'whenadfpipelinefailed'
  location: 'global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    autoMitigate: true
    criteria: {
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
          metricName: 'PipelineFailedRuns'
          metricNamespace: 'Microsoft.DataFactory/factories'
          name: 'Metric1'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Total'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    description: 'send alert when adf pipeline is failed'
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      resourceId('Microsoft.DataFactory/factories', dataFactory.name)
    ]
    severity: 4
    targetResourceType: 'Microsoft.DataFactory/factories'
    windowSize: 'PT1M'
  }
  dependsOn: [
    dataFactory
  ]
}

resource whenadftriggerfailed 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'whenadftriggerfailed'
  location: 'global'
  properties: {
    actions: [
      {
        actionGroupId: actionGroupId
      }
    ]
    autoMitigate: true
    criteria: {
      allOf: [
        {
          criterionType: 'StaticThresholdCriterion'
          dimensions: []
          metricName: 'TriggerFailedRuns'
          metricNamespace: 'Microsoft.DataFactory/factories'
          name: 'Metric1'
          operator: 'GreaterThan'
          threshold: 1
          timeAggregation: 'Total'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
    }
    description: 'send alert when adf trigger failed'
    enabled: true
    evaluationFrequency: 'PT1M'
    scopes: [
      resourceId('Microsoft.DataFactory/factories', dataFactory.name)
    ]
    severity: 4
    targetResourceType: 'Microsoft.DataFactory/factories'
    windowSize: 'PT1M'
  }
  dependsOn: [
    dataFactory
  ]
}

resource managedVNET 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${dataFactory.name}/default'
  properties: {}
}

resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${adfName}/AutoResolveIntegrationRuntime'
  dependsOn: [
    dataFactory
    managedVNET
  ]
  properties: {
    type: 'Managed'
    managedVirtualNetwork: {
      referenceName: 'default'
      type: 'ManagedVirtualNetworkReference'
    }
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
    }
  }
}

// TODO: need to finsih configuration
/*
resource privateLink 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  name: '${name}/something'
  properties: {

  }
}
*/

output id string = dataFactory.id
output name string = dataFactory.name
