param enableSoftDelete bool
param location string
param networkResourceGroupName string
param dnsResourceGroupName string
param resourcePrefix string
param tenantId string
param timeStamp string
param vnetName string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name: '${resourcePrefix}-kv'
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
    enableSoftDelete: enableSoftDelete
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-kv'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-kv'
    serviceResourceId: keyVault.id
    dnsZoneName: 'privatelink.vaultcore.azure.net'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'vault'
  }
}
