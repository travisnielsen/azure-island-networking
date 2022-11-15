@allowed([
  'eastus'
  'eastus2'
  'northcentralus'
  'centralus'
  'westus'
  'westus2'
  'westus3'
])
param region string
param regionCode string
param orgPrefix string
param appPrefix string
param tags object = {
  project: 'AzSecurePaaS'
  component: 'core'
}

@maxLength(16)
@description('The full prefix is the combination of the org prefix and app prefix and cannot exceed 16 characters in order to avoid deployment failures with certain PaaS resources such as storage or key vault')
param fullPrefix string = '${orgPrefix}-${appPrefix}'
var resourcePrefix = '${fullPrefix}-${regionCode}'

var acrName = format('{0}acr', replace(fullPrefix, '-', ''))
resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: acrName
}

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' existing = {
  name: '${resourcePrefix}-kv'
}

resource ehProducer 'Microsoft.Web/sites@2021-03-01' existing = {
  name: '${resourcePrefix}-fa-ehProducer'
}

module acrPullMi 'modules/managedIdentity.bicep' = {
  name: '${appPrefix}-mi-acrPull'
  params: {
    location: region
    resourcePrefix: resourcePrefix
    role: 'acrPull'
    tags: tags
  }
}

module keyVaultSecretUserMi 'modules/managedIdentity.bicep' = {
  name: '${appPrefix}-mi-kvSecrets'
  params: {
    location: region
    resourcePrefix: resourcePrefix
    role: 'kvSecrets'
    tags: tags
  }
}

resource roleAssignmentName 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
  name: guid(containerRegistry.id, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe', ehProducer.name)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
    principalId: reference(ehProducer.id, '2021-03-01', 'full').identity.principalId
  }
  scope: containerRegistry
}

// List of all Built-in Role IDs: https://learn.microsoft.com/en-us/azure/role-based-access-control/built-in-roles
// Key Vault Secrets Role Id: 4633458b-17de-408a-b874-0445c86b69e6
// AcrPull Role Id: 7f951dda-4ed3-4680-a7ca-43fe172d538d
// Event Hubs Data Receiver Role Id: a638d3c7-ab3a-418d-83e6-5f17a39d4fde
// Event Hubs Data Sender Role Id: 2b629674-e913-4c01-ae53-ef4638d8f975
// Service Bus Data Receiever Role Id: 4f6d3b9b-027b-4f4c-9142-0e5a2a2247e0
// Service Bus Data Sender Role Id: 69a216fc-b8fb-44d8-bc22-1f3c2cd27a39
