param serverName string = uniqueString(resourceGroup().id)
param databaseName string
param adminGroupObjectId string
param databaseSku string = 'GP_S_Gen5_1'
param databaseTier string = 'GeneralPurpose'
param useSampleDatabase bool = false
param location string = resourceGroup().location
param resourceGroupNameNetwork string
param resourceGroupNameDns string
param privateLinkVnetName string
param privateLinkSubnetName string

param tags object = {}

resource sqlserver 'Microsoft.Sql/servers@2023-05-01-preview' = {
  name: serverName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    version: '12.0'
    minimalTlsVersion: '1.2'
    publicNetworkAccess: 'Disabled'
    restrictOutboundNetworkAccess: 'Enabled'
    administrators: {
      login: 'sqladmingroup'
      sid: adminGroupObjectId
      tenantId: subscription().tenantId
      azureADOnlyAuthentication: true
      administratorType: 'ActiveDirectory'
      principalType: 'Group'
    }
  }
}

resource sqldb 'Microsoft.Sql/servers/databases@2023-05-01-preview' = {
  name: databaseName
  parent: sqlserver
  location: location
  tags: tags
  sku: {
    name: databaseSku
    tier: databaseTier

  }
  properties: {
    collation: 'SQL_Latin1_General_CP1_CI_AS'
     sampleName: (useSampleDatabase ? 'AdventureWorksLT' : '')

  }
}

module sqlPrivateEndpoint 'privateendpoint.bicep' = {
  name: '${sqlserver.name}-privateendpoint'
  params: {
    location: location
    privateEndpointName: '${sqlserver.name}-sqlEndpoint'
    serviceResourceId: sqlserver.id
    dnsZoneName: 'privatelink${environment().suffixes.sqlServerHostname}'
    dnsResourceGroupName: resourceGroupNameDns
    networkResourceGroupName: resourceGroupNameNetwork
    vnetName: privateLinkVnetName
    subnetName: privateLinkSubnetName
    groupId: 'sqlServer'
  }
}

output sqlServerDnsName string = '${sqlserver.name}${environment().suffixes.sqlServerHostname}'
