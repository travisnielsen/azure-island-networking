param location string
param timeStamp string
param resourcePrefix string
param orgPrefix string
param vnetName string
param tenantId string

resource keyVault 'Microsoft.KeyVault/vaults@2022-07-01' = {
  name:'${resourcePrefix}-kv'
  location: location
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: tenantId
    accessPolicies: []
    enableSoftDelete: false
    enableRbacAuthorization: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Deny'
    }
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-kv-privateEndpoint'
  params: {
    location: location
    privateEndpointName: '${keyVault.name}-endpoint'
    serviceResourceId: keyVault.id
    dnsZoneName: 'privatelink.azurewebsites.net'
    resourceGroupNameNetwork: '${orgPrefix}-network-rg'
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'vault'
  }
}
