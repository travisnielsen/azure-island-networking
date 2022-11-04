param location string
param resourcePrefix string
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
  }
}

module functionPrivateEndpoint 'privateendpoint.bicep' = {
  name: 'function-privateEndpoint'
  params: {
    location: location
    privateEndpointName: '${keyVault.name}-kv-endpoint'
    serviceResourceId: keyVault.id
    dnsZoneName: 'privatelink.azurewebsites.net'
    resourceGroupNameNetwork: '${resourcePrefix}-network-rg'
    vnetName: '${resourcePrefix}-workload-a'
    subnetName: 'privateendponts'
    // subnetId: resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetNamePrivateEndpoint)
    // dnsZoneId: resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azurewebsites.net' )
    groupId: 'sites'
  }
}
