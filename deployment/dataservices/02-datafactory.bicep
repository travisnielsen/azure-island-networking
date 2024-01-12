param integrationRuntimeName string
param dataFactoryCredentialName string

// SQL Server Information
param sqlServerDnsName string
param databaseName string

// Service Principal Information
param keyVaultName string
param servicePrincipalAppId string
param keyVaultSecretName string

// Fabric Information
param fabricWorkspaceId string
param fabricArtifactId string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: 'contoso-adf'
  scope: resourceGroup()
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: keyVaultName
  scope: resourceGroup()
}

module sqlDatabaseLinkedService '../modules/datafactorylinkedserviceSql.bicep' = {
  name: 'sqlDatabaseLinkedService'
  scope: resourceGroup()
  params: {
    linkedServiceName: 'sqlDatabaseLinkedService'
    linkedServiceType: 'AzureSqlDatabase'
    dataFactoryName: dataFactory.name
    integrationRuntimeName: integrationRuntimeName
    credentialName: dataFactoryCredentialName
    resourceFqdn: sqlServerDnsName
    itemContainerName: databaseName
  }
}

module keyVaultLinkedService '../modules/datafactorylinkedservicekeyvault.bicep' = {
  name: 'keyVaultLinkedService'
  scope: resourceGroup()
  dependsOn: [
    dataFactory
  ]
  params: {
    linkedServiceName: 'keyVaultLinkedService'
    dataFactoryName: dataFactory.name
    valutUri: keyVault.properties.vaultUri
  }

}

module fabricCredential '../modules/datafactoryCredentialServicePrincipal.bicep' = {
  name: 'fabricCredential'
  scope: resourceGroup()
  dependsOn: [
    keyVaultLinkedService
  ]
  params: {
    credentialName: 'contoso-adf-fabric'
    dataFactoryName: dataFactory.name
    servicePrincipalId: servicePrincipalAppId
    keyVaultLinkedServiceName: keyVaultLinkedService.outputs.linkedServiceName
    secretName: keyVaultSecretName
  }
}

module fabricLinkedService '../modules/datafactoryLinkedServiceFabricLakehouse.bicep' = {
  name: 'fabricLinkedService'
  scope: resourceGroup()
  dependsOn: [
    fabricCredential
  ]
  params: {
    linkedServiceName: 'fabricLakehouse'
    dataFactoryName: dataFactory.name
    credentialName: fabricCredential.outputs.credentialName
    fabricWorkspaceId: fabricWorkspaceId
    fabricArtifactId: fabricArtifactId
  }
}

resource fabricDataSetProductsSql 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'SqlProductTable'
  properties: {
    type: 'AzureSqlTable'
    linkedServiceName: {
      referenceName: sqlDatabaseLinkedService.outputs.linkedServiceName
      type: 'LinkedServiceReference'
    }
    typeProperties: {
      schema: 'SalesLT'
      table: 'Product'
    }
    annotations:[]
    schema: [
      {
        name: 'ProductID'
        type: 'int'
        precision: 10
      }
      {
        name: 'Name'
        type: 'nvarchar'
      }
      {
          name: 'ProductNumber'
          type: 'nvarchar'
      }
      {
          name: 'Color'
          type: 'nvarchar'
      }
      {
          name: 'StandardCost'
          type: 'money'
          precision: 19
          scale: 4
      }
      {
          name: 'ListPrice'
          type: 'money'
          precision: 19
          scale: 4
      }
      {
          name: 'Size'
          type: 'nvarchar'
      }
      {
          name: 'Weight'
          type: 'decimal'
          precision: 8
          scale: 2
      }
      {
          name: 'ProductCategoryID'
          type: 'int'
          precision: 10
      }
      {
          name: 'ProductModelID'
          type: 'int'
          precision: 10
      }
      {
          name: 'SellStartDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'SellEndDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'DiscontinuedDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'ThumbNailPhoto'
          type: 'varbinary'
      }
      {
          name: 'ThumbnailPhotoFileName'
          type: 'nvarchar'
      }
      {
          name: 'rowguid'
          type: 'uniqueidentifier'
      }
      {
          name: 'ModifiedDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
    ]
  }
}

resource fabricDataSetProductsLakehouse 'Microsoft.DataFactory/factories/datasets@2018-06-01' = {
  parent: dataFactory
  name: 'LakehouseProductTable'
  properties: {
    type: 'LakehouseTable'
    linkedServiceName: {
      referenceName: fabricLinkedService.outputs.linkedServiceName
      type: 'LinkedServiceReference'
    }
    typeProperties: {
      table: 'Products'
    }
    annotations:[]
    schema: [
      {
        name: 'ProductID'
        type: 'int'
        precision: 10
      }
      {
        name: 'Name'
        type: 'nvarchar'
      }
      {
          name: 'ProductNumber'
          type: 'nvarchar'
      }
      {
          name: 'Color'
          type: 'nvarchar'
      }
      {
          name: 'StandardCost'
          type: 'money'
          precision: 19
          scale: 4
      }
      {
          name: 'ListPrice'
          type: 'money'
          precision: 19
          scale: 4
      }
      {
          name: 'Size'
          type: 'nvarchar'
      }
      {
          name: 'Weight'
          type: 'decimal'
          precision: 8
          scale: 2
      }
      {
          name: 'ProductCategoryID'
          type: 'int'
          precision: 10
      }
      {
          name: 'ProductModelID'
          type: 'int'
          precision: 10
      }
      {
          name: 'SellStartDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'SellEndDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'DiscontinuedDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
      {
          name: 'ThumbNailPhoto'
          type: 'varbinary'
      }
      {
          name: 'ThumbnailPhotoFileName'
          type: 'nvarchar'
      }
      {
          name: 'rowguid'
          type: 'uniqueidentifier'
      }
      {
          name: 'ModifiedDate'
          type: 'datetime'
          precision: 23
          scale: 3
      }
    ]
  }
}

resource copyPipeline 'Microsoft.DataFactory/factories/pipelines@2018-06-01' = {
  parent: dataFactory
  name: 'CopyProducts'
  properties: {
    activities: [
      {
        name: 'CopyProducts'
        type: 'Copy'
        dependsOn: []
        policy: {
          timeout: '0.12:00:00'
          retry: 3
          retryIntervalInSeconds: 30
          secureInput: false
          secureOutput: false
        }
        userProperties: []
        typeProperties: {
          source: {
            type: 'SqlSource'
            queryTimeout: '02:00:00'
            partitionOption: 'None'
          }
          sink: {
            type: 'LakehouseTableSink'
            tableActionOption: 'Append'
          }
          enableStaging: false
          translator: {
            type: 'TabularTranslator'
            typeConversion: true
            typeConversionSettings: {
              allowDataTruncation: true
              treatBooleanAsNumber: false
            }
          }
        }
        inputs: [
          {
            referenceName: fabricDataSetProductsSql.name
            type: 'DatasetReference'
          }
        ]
        outputs: [
          {
            referenceName: fabricDataSetProductsLakehouse.name
            type: 'DatasetReference'
          }
        ]
      }
    ]
    annotations: []
  }
}
