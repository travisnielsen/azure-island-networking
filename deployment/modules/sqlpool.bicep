param sqlServerName string
param sqlPoolName string
param sqlPoolSKU string
param adminLoginName string
@secure()
param adminLoginPwd string
param adminObjectId string
param resourceGroupNameNetwork string
param vnetNamePrivateEndpoint string
param subnetNamePrivateEndpoint string
//param logAnalyticsWorkspaceId string
param actionGroupId string
param tags object
param location string
param subscriptionId string

var blocContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var sqlDefenderContainerName = 'defender'

resource auditstorage 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: 'sqlops${uniqueString(resourceGroup().id)}'
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
  tags: tags
}

resource defendercontainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${auditstorage.name}/default/${sqlDefenderContainerName}'
}

var containerSasProperties = {
  canonicalizedResource: '/blob/${auditstorage.name}/${sqlDefenderContainerName}'
  signedService: 'c'
  signedPermission: 'rw'
  signedExpiry: '2021-07-01T00:00:01Z'
}

resource sqlserver 'Microsoft.Sql/servers@2019-06-01-preview' = {
  name: sqlServerName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    administratorLogin: 'sqladmin'
    administratorLoginPassword: adminLoginPwd
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
  }
}

resource sqladmin 'Microsoft.Sql/servers/administrators@2019-06-01-preview' = {
  name: '${sqlserver.name}/ActiveDirectory'
  properties: {
    administratorType: 'ActiveDirectory'
    login: adminLoginName
    sid: adminObjectId
    tenantId: subscription().tenantId
  }
}

module sqlPrivateEndpoint 'privateendpoint.bicep' = {
  name: '${sqlserver.name}-privateendpoint'
  params: {
    location: location
    privateEndpointName: '${sqlserver.name}-sqlEndpoint'
    serviceResourceId: sqlserver.id
    dnsZoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    resourceGroupNameNetwork: resourceGroupNameNetwork
    vnetName: vnetNamePrivateEndpoint
    subnetName: subnetNamePrivateEndpoint
    groupId: 'sqlServer'
  }
}

/*
resource sqlServerDiagnosticSettings 'microsoft.insights/diagnosticSettings@2017-05-01-preview' = {
  name: '${sqldb.name}-diagnostics'
  dependsOn: [
    sqlserver
  ]
  scope: sqlserver
  properties: {
    workspaceId: logAnalyticsWorkspaceId
    logs: [
      {
        category: 'SQLSecurityAuditEvents'
        enabled: true
        retentionPolicy: {
          days: 7
          enabled: true
        }
      }
    ]
  }
}
*/

resource roleassignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(blocContributorRoleId, resourceGroup().id)
  scope: auditstorage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blocContributorRoleId)
    principalId: sqlserver.identity.principalId
    principalType: 'ServicePrincipal'
  }
}

resource auditsettings 'Microsoft.Sql/servers/auditingSettings@2017-03-01-preview' = {
  name: '${sqlserver.name}/DefaultAuditSettings'
  dependsOn: [
    roleassignment
    // sqlServerDiagnosticSettings
  ]
  properties: {
    state: 'Enabled'
    storageEndpoint: auditstorage.properties.primaryEndpoints.blob
    storageAccountSubscriptionId: subscriptionId
    isStorageSecondaryKeyInUse: false
    isAzureMonitorTargetEnabled: false
    auditActionsAndGroups: [
      'BATCH_COMPLETED_GROUP'
      'FAILED_DATABASE_AUTHENTICATION_GROUP'
      'DATABASE_OBJECT_OWNERSHIP_CHANGE_GROUP'
      'DATABASE_OBJECT_PERMISSION_CHANGE_GROUP'
      'DATABASE_PERMISSION_CHANGE_GROUP'
      'DATABASE_PRINCIPAL_CHANGE_GROUP'
      'DATABASE_ROLE_MEMBER_CHANGE_GROUP'
    ]
  }
}

resource securityAlertsPolicy 'Microsoft.Sql/servers/securityAlertPolicies@2020-02-02-preview' = {
  name: '${sqlserver.name}/DefaultSecurityAlertPolicy'
  properties: {
    state: 'Enabled'
  }
}

resource azuredefender 'Microsoft.Sql/servers/vulnerabilityAssessments@2018-06-01-preview' = {
  name: '${sqlserver.name}/DefaultAssesment'
  dependsOn: [
    roleassignment
    securityAlertsPolicy
  ]
  properties: {
    storageContainerPath: '${auditstorage.properties.primaryEndpoints.blob}defender'
    storageContainerSasKey: listServiceSas(auditstorage.name, '2018-02-01', containerSasProperties).serviceSasToken
    recurringScans: {
      emails: [
        'security@contoso.com'
      ]
      emailSubscriptionAdmins: true
      isEnabled: true
    }
  }
}

resource sqldb 'Microsoft.Sql/servers/databases@2020-08-01-preview' = {
  name: '${sqlServerName}/${sqlPoolName}'
  location: location
  dependsOn: [
    sqlserver
  ]
  sku: {
    name: sqlPoolSKU // DW100c
    tier: 'DataWarehouse'
  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
    // sampleName: 'AdventureWorksLT'
    // sampleName: 'WideWorldImportersFull'
  }
}

/*
Metric alerts for SQL db
*/
resource sqlHighCPU 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'SQL Server CPU percentage is high'
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
          alertSensitivity: 'Medium'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 4
          }
          name: 'Metric1'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          metricName: 'cpu_percent'
          operator: 'GreaterOrLessThan'
          timeAggregation: 'Average'
          criterionType: 'DynamicThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    description: 'SQL server CPU is higher than normal'
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      sqldb.id
    ]
    severity: 4
    targetResourceType: 'Microsoft.Sql/servers/databases'
    windowSize: 'PT5M'
  }
  dependsOn: [
    sqlserver
  ]
}

resource failedConnections 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'Total failed connections'
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
          alertSensitivity: 'Medium'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 4
          }
          name: 'Metric2'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          metricName: 'connection_failed'
          operator: 'GreaterOrLessThan'
          timeAggregation: 'Total'
          criterionType: 'DynamicThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    description: 'SQL server total failed connections'
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      sqldb.id
    ]
    severity: 4
    targetResourceType: 'Microsoft.Sql/servers/databases'
    windowSize: 'PT5M'
  }
  dependsOn: [
    sqlserver
  ]
}

resource highDTU 'Microsoft.Insights/metricAlerts@2018-03-01' = {
  name: 'DTU Utilization is over threshold'
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
          alertSensitivity: 'Medium'
          failingPeriods: {
            numberOfEvaluationPeriods: 4
            minFailingPeriodsToAlert: 4
          }
          name: 'Metric3'
          metricNamespace: 'Microsoft.Sql/servers/databases'
          metricName: 'dwu_used'
          operator: 'GreaterOrLessThan'
          timeAggregation: 'Maximum'
          criterionType: 'DynamicThresholdCriterion'
        }
      ]
      'odata.type': 'Microsoft.Azure.Monitor.MultipleResourceMultipleMetricCriteria'
    }
    description: 'SQL server DTU Utilization is over threshold'
    enabled: true
    evaluationFrequency: 'PT5M'
    scopes: [
      sqldb.id
    ]
    severity: 4
    targetResourceType: 'Microsoft.Sql/servers/databases'
    windowSize: 'PT5M'
  }
  dependsOn: [
    sqlserver
  ]
}

output id string = sqlserver.id
output serverName string = sqlserver.name
output databaseName string = sqldb.name
