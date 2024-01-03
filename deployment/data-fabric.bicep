param orgPrefix string
param appPrefix string
param regionCode string
param location string = resourceGroup().location
param tags object = { }
@maxLength(16)
@description('The full prefix is the combination of the org prefix and app prefix and cannot exceed 16 characters in order to avoid deployment failures with certain PaaS resources such as storage or key vault')
param fullPrefix string = '${orgPrefix}-${appPrefix}'

// Naming Convention
var resourcePrefix = '${fullPrefix}-${regionCode}'

// Networking
param dnsResourceGroupName string = '${orgPrefix}-core-dns'
param networkResourceGroupName string = '${orgPrefix}-core-network'
param vnetName string = '${orgPrefix}-core-${regionCode}-spoke'

// SQL server 
param sqlAdminObjectId string
param databaseName string = 'adventureworks'
param sqlDatabaseSKU string = 'GP_S_Gen5_1'

// Virtual Machines
param vmAdminUserName string
@secure()
param vmAdminPwd string

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
  scope: resourceGroup(subscription().id, networkResourceGroupName)
}

module sqlDabase 'modules/sqldb.bicep' = {
  name: 'sqlDabase'
  scope: resourceGroup()
  params: {
    databaseName: databaseName
    databaseSku: sqlDatabaseSKU
    adminGroupObjectId: sqlAdminObjectId
    resourceGroupNameDns: dnsResourceGroupName
    resourceGroupNameNetwork: networkResourceGroupName
    vnetName: vnet.name
    subnetName: 'privatelink'
    location: location
    useSampleDatabase: true
    tags: tags
  }
}

module windows11vm 'modules/virtualMachine.bicep' = {
  name: 'windows11vm'
  scope: resourceGroup()
  params: {
    vmName: 'win11vm'
    vmSize: 'Standard_D2s_v4'
    os: 'windows11'
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
    networkResourceGroupName: networkResourceGroupName
    vnetName: vnet.name
    subnetName: 'iaas'
    location: location
    tags: tags
    initScriptBase64: loadFileAsBase64('win11setup.cmd')
  }
}
