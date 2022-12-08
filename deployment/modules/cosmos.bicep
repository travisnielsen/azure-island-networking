param location string
param networkResourceGroupName string
param dnsResourceGroupName string
param resourcePrefix string
param timeStamp string
param vnetName string

resource cosmos 'Microsoft.DocumentDB/databaseAccounts@2022-05-15' = {
  name: '${resourcePrefix}-acdb'
  location: location
  properties: {
    locations: [
      {
        locationName: location
      }
    ]
    databaseAccountOfferType: 'Standard'
    networkAclBypass: 'AzureServices'
    publicNetworkAccess: 'Disabled'
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-pe-cosmos'
  scope: resourceGroup(networkResourceGroupName)
  params: {
    location: location
    privateEndpointName: '${resourcePrefix}-pe-cosmos'
    serviceResourceId: cosmos.id
    dnsZoneName: 'privatelink.documents.azure.com'
    networkResourceGroupName: networkResourceGroupName
    dnsResourceGroupName: dnsResourceGroupName
    vnetName: vnetName
    subnetName: 'privateEndpoints'
    groupId: 'Sql'
  }
}
