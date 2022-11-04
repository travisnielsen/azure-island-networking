param appPrefix string
param tags object = {
  project: 'AzSecurePaaS'
  component: 'app'
}

param sqlAdminLoginName string
@secure()
param sqlAdminLoginPwd string
param sqlAdminObjectId string

param storageContainerName string = 'testdata'
param sqlDatabaseName string = 'nytaxi'
param sqlDatabaseSKU string = 'DW100c'

param location string = resourceGroup().location

// VNet integration
var subscriptionId = subscription().subscriptionId

var networkResourceGroupName = '${appPrefix}-network'
var vnetName = '${appPrefix}-app'

var sqlServerName = '${uniqueString(resourceGroup().id)}-sql'
var dataFactoryName = '${uniqueString(resourceGroup().id)}-df'

// Deploy Action Group for monitoring/alerting
module actionGroup 'modules/actionGroup.bicep' = {
  name: 'actionGroup'
  params: {
    actionGroupName: 'wbademo-appadmin'
    actionGroupShortName: 'wbademoadmin'
  }
}

/*
 *  Storage account
 */
resource storageAccount 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
  tags: tags
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2019-06-01' = {
  name: '${storageAccount.name}/default/${storageContainerName}'
}

/*
 *  Log Analytics
 */
module logAnalytics 'modules/loganalytics.bicep' = {
  name: 'logAnalytics'
  params: {
    location: location
    name: uniqueString(resourceGroup().id)
    appTags: tags
  }
}

module storagePrivateEndpoint 'modules/privateendpoint.bicep' = {
  name: 'storageAccount-privateEndpoint'
  params: {
    location: location
    privateEndpointName: '${storageAccount.name}-storageEndpoint'
    serviceResourceId: storageAccount.id
    resourceGroupNameNetwork: networkResourceGroupName
    vnetName: vnetName
    subnetName: 'azureServices'
    // dnsZoneId: resourceId(subscriptionId, 'Microsoft.Network/privateDnsZones', 'privatelink.blob.core.windows.net' )
    dnsZoneName: 'privatelink.blob.${environment().suffixes.storage}'
    groupId: 'blob'
  }
}

/*
 *  Dedicated SQL Pool (SQL DW) instance
 */
module sqlSynapse 'modules/sqlpool.bicep' = {
  name: 'sql-dedicatedpool'
  params: {
    location: location
    subscriptionId: subscriptionId
    sqlServerName: sqlServerName
    sqlPoolName: sqlDatabaseName
    sqlPoolSKU: sqlDatabaseSKU
    adminLoginName: sqlAdminLoginName
    adminLoginPwd: sqlAdminLoginPwd
    adminObjectId: sqlAdminObjectId
    resourceGroupNameNetwork: networkResourceGroupName
    vnetNamePrivateEndpoint: vnetName
    subnetNamePrivateEndpoint: 'azureServices'
    //logAnalyticsWorkspaceId: logAnalytics.outputs.id
    actionGroupId: actionGroup.outputs.id
    tags: tags
  }
}

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  dependsOn: [
    storageAccount
    sqlSynapse
  ]
  location: location
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

module dataFactoryPrivateEndpoint 'modules/privateendpoint.bicep' = {
  name: 'datafactory-privateEndpoint'
  params: {
    location: location
    privateEndpointName: '${dataFactory.name}-dataFactoryEndpoint'
    serviceResourceId: dataFactory.id
    resourceGroupNameNetwork: networkResourceGroupName
    vnetName: vnetName
    subnetName: 'azureServices'
    dnsZoneName: 'privatelink.datafactory.azure.net'
    groupId: 'dataFactory'
  }
}

resource dataFactoryManagedVNET 'Microsoft.DataFactory/factories/managedVirtualNetworks@2018-06-01' = {
  name: '${dataFactory.name}/default'
  properties: {
  }
}

resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${dataFactory.name}/AutoResolveIntegrationRuntime'
  dependsOn: [
    dataFactoryManagedVNET
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

// ADF: Managed private endpoints

resource managedPrivEndpointSql 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  name: '${dataFactory.name}/default/SqlSynapse1'
  dependsOn: [
    dataFactoryManagedVNET
  ]
  properties: {
    groupId: 'sqlServer'
    privateLinkResourceId: sqlSynapse.outputs.id
  }
}

resource managedPrivEndpointBlob 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  name: '${dataFactory.name}/default/BlobStorage1'
  dependsOn: [
    dataFactoryManagedVNET
    storagePrivateEndpoint
  ]
  properties: {
    groupId: 'blob'
    privateLinkResourceId: storageAccount.id
  }
}

// TODO: Create CLI script to approve private link service connection created by the ADF Managed Private Endpoints settings

// ADF: Linked services

resource adfLinkedServiceSql 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${dataFactory.name}/SqlSynapse1'
  dependsOn: [
    integrationRuntime
  ]
  properties: {
    type: 'AzureSqlDW'
    typeProperties: {
      connectionString: 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${sqlServerName}.database.windows.net;Initial Catalog=${sqlDatabaseName}'
    }
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
}

resource adfLinkedServiceBlob 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: '${dataFactory.name}/BlobStorage1'
  dependsOn: [
    integrationRuntime
  ]
  properties: {
    type: 'AzureBlobStorage'
    typeProperties: {
      serviceEndpoint: 'https://${storageAccount.name}.blob.${environment().suffixes.storage}'
      accountKind: storageAccount.kind
    }
    connectVia: {
      referenceName: 'AutoResolveIntegrationRuntime'
      type: 'IntegrationRuntimeReference'
    }
  }
}

resource adfDatasetSynapse 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactory.name}/AzureSynapseAnalyticsTable1'
  dependsOn: [
    adfLinkedServiceSql
  ]
  properties: {
    linkedServiceName: {
      referenceName: 'SqlSynapse1'
      type: 'LinkedServiceReference'
    }
    type: 'AzureSqlDWTable'
    schema: []
    typeProperties: {
      table: {
        value: '@concat(\'tbl\', string(rand(1000000,9999999)))'
        type: 'Expression'
      }
    }
  }
}

resource adfDatasetBlob 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  name: '${dataFactory.name}/DelimitedText1'
  dependsOn: [
    adfLinkedServiceBlob
  ]
  properties: {
    linkedServiceName: {
      referenceName: 'BlobStorage1'
      type: 'LinkedServiceReference'
    }
    type: 'DelimitedText'
    typeProperties: {
      location: {
        type: 'AzureBlobStorageLocation'
        container: 'testdata'
      }
      // columnDelimiter: ','
      // escapeChar: '\\'
      // quoteChar: '\\"'
    }
  }
}

resource adfDataFlow 'Microsoft.DataFactory/factories/dataflows@2018-06-01' = {
  name: '${dataFactory.name}/dataflow1'
  dependsOn: [
    adfDatasetBlob
    adfDatasetSynapse
  ]
  properties: {
    type: 'MappingDataFlow'
    typeProperties: {
      sources: [
        {
          dataset: {
            referenceName: 'DelimitedText1'
            type: 'DatasetReference'
          }
          name: 'source1'
        }
      ]
      sinks: [
        {
          dataset: {
            referenceName: 'AzureSynapseAnalyticsTable1'
            type: 'DatasetReference'
          }
          name: 'sink1'
        }
      ]
      // transformations: [
      // ]
      script: 'source(allowSchemaDrift: true,\n\tvalidateSchema: false,\n\tignoreNoFilesFound: false,\n\tpurgeFiles: true,\n\twildcardPaths:[\'*.csv\']) ~> source1\nsource1 sink(allowSchemaDrift: true,\n\tvalidateSchema: false,\n\tdeletable:false,\n\tinsertable:true,\n\tupdateable:false,\n\tupsertable:false,\n\trecreate:true,\n\tformat: \'table\',\n\tstaged: false,\n\tskipDuplicateMapInputs: true,\n\tskipDuplicateMapOutputs: true,\n\tsaveOrder: 1) ~> sink1'
    }
  }
}

resource adfPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  name: '${dataFactory.name}/pipeline1'
  dependsOn: [
    adfDataFlow
    integrationRuntime
  ]
  properties: {
    activities: [
      {
        name: 'Data flow1'
        type: 'ExecuteDataFlow'
        dependsOn: []
        policy: {
          timeout: '7.00:00:00'
          retry: 0
          retryIntervalInSeconds: 30
          secureOutput: false
          secureInput: false
        }
        userProperties: []
        typeProperties: {
          dataFlow: {
            referenceName: 'dataflow1'
            type: 'DataFlowReference'
            parameters: {}
            datasetParameters: {
              source1: {}
              sink1: {}
            }
            staging: {}
            compute: {
              coreCount: 8
              computeType: 'General'
            }
            traceLevel: 'Fine'
          }
        }
      }
    ]
  }
}

resource adfTrigger 'Microsoft.DataFactory/factories/triggers@2018-06-01' = {
  name: '${dataFactory.name}/trigger1'
  dependsOn: [
    adfPipeline
  ]
  properties: {
    pipelines: [
      {
        pipelineReference: {
          referenceName: 'pipeline1'
          type: 'PipelineReference'
        }
        parameters: {}
      }
    ]
    type: 'BlobEventsTrigger'
    typeProperties: {
      blobPathBeginsWith: '/testdata/blobs/'
      ignoreEmptyBlobs: true
      scope: '/subscriptions/7a8fb3e5-9699-4869-93b4-c011fb7fc532/resourceGroups/contoso-data/providers/Microsoft.Storage/storageAccounts/bi2sz4tdlw5e4'
      events: [
        'Microsoft.Storage.BlobCreated'
      ]
    }
  }
}

// Storage: Grant data read access to ADF managed identity

// var roleAssignmentName_var = guid(resourceId('Microsoft.Storage/storageAccounts/', storageAccount.name), 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', dataFactory.name)

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(storageAccount.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', dataFactory.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: reference(dataFactory.id, '2018-06-01', 'full').identity.principalId
  }
  scope: storageAccount
}
