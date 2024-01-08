param linkedServiceName string
param dataFactoryName string
param credentialName string
param fabricWorkspaceId string
param fabricArtifactId string


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
  scope: resourceGroup()
}

resource fabricLinkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: linkedServiceName
  parent: dataFactory
  properties: {
    type: 'Lakehouse'
    typeProperties: {
      workspaceResourceId: fabricWorkspaceId
      artifactId: fabricArtifactId
      servicePrincipalCredentialType: 'ServicePrincipalKey'
      credential: {
        referenceName: credentialName
        type: 'CredentialReference'
      }
    }
  }
}
