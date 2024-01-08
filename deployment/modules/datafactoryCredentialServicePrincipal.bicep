param credentialName string
param dataFactoryName string
param servicePrincipalId string
param keyVaultLinkedServiceName string
param secretName string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
  scope: resourceGroup()
}

resource dataFactoryCredential 'Microsoft.DataFactory/factories/credentials@2018-06-01' = {
  name: credentialName
  parent: dataFactory
  properties: {
    type: 'ServicePrincipal'
    typeProperties: {
      tenant: subscription().tenantId
      servicePrincipalId: servicePrincipalId
      servicePrincipalKey: {
        type: 'AzureKeyVaultSecret'
        store: {
          referenceName: keyVaultLinkedServiceName
          type: 'LinkedServiceReference'
        }
        secretName: secretName
      }
    }
  }
}

output credentialName string = dataFactoryCredential.name
