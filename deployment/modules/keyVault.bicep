param valutName string
param enableSoftDelete bool = false
param location string = resourceGroup().location
param networkResourceGroupName string
param dnsResourceGroupName string
param resourcePrefix string
param tenantId string = subscription().tenantId
param vnetName string
param subnetName string

#disable-next-line secure-secrets-in-params   // Doesn't contain a secret
param secretsReaderObjectId string = ''
@allowed([
  'ServicePrincipal'
  'User'
])
#disable-next-line secure-secrets-in-params   // Doesn't contain a secret
param secretsReaderObjectType string = 'ServicePrincipal'

var keyVaultSecretsUserRoleId = '4633458b-17de-408a-b874-0445c86b69e6'

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: valutName
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
    enableSoftDelete: enableSoftDelete
    softDeleteRetentionInDays: 90
    enableRbacAuthorization: true
    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${resourcePrefix}-pe-kv'
  params: {
    location: location
    privateEndpointName: '${keyVault.name}-vaultendpoint'
    serviceResourceId: keyVault.id
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: subnetName
    groupId: 'vault'
  }
}

/*

*/

resource keyVaultSecretsUserRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (!empty(secretsReaderObjectId)) {
  scope: keyVault
  name: guid(tenantId, keyVault.id, keyVaultSecretsUserRoleId)
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUserRoleId)
    principalId: secretsReaderObjectId
    principalType: secretsReaderObjectType
  }
}

output keyVaultUri string = keyVault.properties.vaultUri
output keyVaultName string = keyVault.name
