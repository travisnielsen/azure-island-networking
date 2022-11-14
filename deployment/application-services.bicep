param timeStamp string = utcNow('yyyyMMddHHmm')
param appPrefix string
param orgPrefix string
param regionCode string
param location string = resourceGroup().location
param zoneRedundant bool = false
@maxLength(16)
@description('The full prefix is the combination of the org prefix and app prefix and cannot exceed 16 characters in order to avoid deployment failures with certain PaaS resources such as storage or key vault')
param fullPrefix string = '${orgPrefix}-${appPrefix}'

param utilVmAdminUserName string = 'vmadmin'
@secure()
param utilVmAdminPwd string
param utilVmSubnetName string = 'util'


var resourcePrefix = '${fullPrefix}-${regionCode}'
var workloadVnetName = fullPrefix
var tenantId = subscription().tenantId
var resourceGroupNameNetwork = '${orgPrefix}-network'

//NOTE: This is set to false for ease of testing and rapid iteration on changes.  For real workloads this should be set to true
var enableSoftDeleteForKeyVault = false

var functionApps = [
  {
    functionAppNameSuffix: 'ehConsumer'
    storageAccountNameSuffix: 'ehconsumer'
    dockerImageAndTag: 'cdcehconsumer:latest'
  }
  {
    functionAppNameSuffix: 'sbConsumer'
    storageAccountNameSuffix: 'sbconsumer'
    dockerImageAndTag: 'cdcsbconsumer:latest'
  }
  {
    functionAppNameSuffix: 'ehProducer'
    storageAccountNameSuffix: 'ehproducer'
    dockerImageAndTag: 'cdcehproducer:latest'
  }
]

var entities = [
  'poc.customers.addresses'
]

/*
// TODO - Refactor to parameterize vnet name
// TODO - This is all jacked up around managed identities
module aks 'modules/aks.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-aks'
  params: {
    location: location
    resourcePrefix: resourcePrefix
    subnetId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${orgPrefix}-network/providers/Microsoft.Network/virtualNetworks/${appPrefix}-vnet/subnets/aks'
  }
}
*/

module keyVault 'Modules/keyVault.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-kv'
  params: {
    enableSoftDelete: enableSoftDeleteForKeyVault
    location: location
    resourceGroupNameNetwork: resourceGroupNameNetwork
    resourcePrefix: resourcePrefix
    tenantId: tenantId
    timeStamp: timeStamp
    vnetName: workloadVnetName
  }
}

module monitoring 'Modules/monitoring.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-monitoring'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}

module eventHub 'Modules/eventHub.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-eventHub'
  params: {
    eventHubNames: entities
    location: location
    resourceGroupNameNetwork: resourceGroupNameNetwork
    resourcePrefix: resourcePrefix
    timeStamp: timeStamp
    vnetName: workloadVnetName
    zoneRedundant: zoneRedundant
  }
}

module serviceBus 'Modules/serviceBus.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-serviceBus'
  params: {
    location: location
    resourceGroupNameNetwork: resourceGroupNameNetwork
    queueNames: entities
    resourcePrefix: resourcePrefix
    timeStamp: timeStamp
    vnetName: workloadVnetName
    zoneRedundant: zoneRedundant
  }
}

module containerRegistry 'Modules/containerRegistry.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-acr'
  params: {
    location: location
    resourceGroupNameNetwork: resourceGroupNameNetwork
    resourcePrefix: resourcePrefix
    timeStamp: timeStamp
    vnetName: workloadVnetName
  }
}

/*
module cosmos 'Modules/cosmos.bicep' = {
  name: '${timeStamp}-${resourcePrefix}-cosmos'
  params: {
    location: location
    resourcePrefix: resourcePrefix
  }
}
*/

var functionAppsCount = length(functionApps)
module functions 'Modules/functionapp.bicep' = [for i in range(0, functionAppsCount): {
  name: '${timeStamp}-${resourcePrefix}-${functionApps[i].functionAppNameSuffix}'
  params: {
    dockerImageAndTag: functionApps[i].dockerImageAndTag
    functionAppNameSuffix: functionApps[i].functionAppNameSuffix
    functionSubnetId: '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroupNameNetwork}/providers/Microsoft.Network/virtualNetworks/${workloadVnetName}/subnets/${functionApps[i].functionAppNameSuffix}'
    location: location
    resourceGroupNameNetwork: resourceGroupNameNetwork
    resourcePrefix: resourcePrefix
    storageSkuName: 'Standard_LRS'
    storageAccountNameSuffix: functionApps[i].storageAccountNameSuffix
    timeStamp: timeStamp
    vnetName: workloadVnetName
    zoneRedundant: zoneRedundant    
  }
  dependsOn: [
    monitoring
  ]
}]

// utility server for traffic testing
module webServer 'modules/virtualMachine.bicep' = {
  name: 'util-server-consoso-com'
  params: {
    adminUserName: utilVmAdminUserName
    adminPassword: utilVmAdminPwd
    networkResourceGroupName: resourceGroupNameNetwork
    location: location
    vnetName: workloadVnetName
    subnetName: utilVmSubnetName
    os: 'linux'
    vmName: '${resourcePrefix}-util01'
    vmSize: 'Standard_B2ms'
  }
}
