param linkedServiceName string
param dataFactoryName string

@description('The name of the linked service type. Example: AzureSqlDatabase.')
@allowed([  'AzureSqlDatabase'
            'AzureSqlDW' ])
param linkedServiceType string
@description('The fully qualified DNS name of the resource. Example: myservername.database.windows.net')
param resourceFqdn string
@description('The name of the database or container used as part of the connnection string. Example: adventureworks')
param itemContainerName string
param credentialName string
param integrationRuntimeName string


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
  scope: resourceGroup()
}

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: linkedServiceName
  parent: dataFactory
  properties: {
    #disable-next-line BCP225
    type: linkedServiceType
    typeProperties: {
      connectionString: 'Integrated Security=False;Encrypt=True;Connection Timeout=30;Data Source=${resourceFqdn};Initial Catalog=${itemContainerName}'
      credential: {
        referenceName: credentialName
        type: 'CredentialReference'
      }
    }
    connectVia: {
      referenceName: integrationRuntimeName
      type: 'IntegrationRuntimeReference'
    }
  }
}
