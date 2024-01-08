param dataFactoryName string
param location string = resourceGroup().location
param identityId string
param resourceGroupNameDns string
param resourceGroupNameNetwork string
param privateLinkVnetName string
param privateLinkSubnetName string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned,UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
      }
  }
}

resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${dataFactoryName}-ir'
  parent: dataFactory
  properties: {
    type: 'SelfHosted'
  }
}

resource dataFactoryCredential 'Microsoft.DataFactory/factories/credentials@2018-06-01' = {
  name: '${dataFactoryName}-userAssignedCredential'
  parent: dataFactory
  properties: {
    type: 'ManagedIdentity'
    typeProperties: {
      resourceId: identityId
    }
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${dataFactory.name}-privateendpoint'
  params: {
    location: location
    privateEndpointName: '${dataFactory.name}-endpoint'
    serviceResourceId: dataFactory.id
    dnsZoneName: 'privatelink.datafactory.azure.net'
    dnsResourceGroupName: resourceGroupNameDns
    networkResourceGroupName: resourceGroupNameNetwork
    vnetName: privateLinkVnetName
    subnetName: privateLinkSubnetName
    groupId: 'dataFactory'
  }
}

var integrationRuntimeKey = integrationRuntime.listAuthKeys().authKey1

output name string = dataFactory.name
output dataFactoryId string = dataFactory.id
output dataFactoryManagedIdentity string = dataFactory.identity.principalId
output integrationRuntimeName string = integrationRuntime.name
output integrationRuntimeId string = integrationRuntime.id
output integrationRuntimeKey string = integrationRuntimeKey
output dataFactoryCredentialId string = dataFactoryCredential.id
output dataFactoryCredentialName string = dataFactoryCredential.name
