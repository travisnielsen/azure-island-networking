param orgPrefix string
param appPrefix string
param regionCode string
param location string = resourceGroup().location
param tags object = { }
@maxLength(30)
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

// Identities
param userAssignedIdentityName string
@secure()
param servicePrincipalSecret string
param updateServicePrincipalSecret bool = false

var keyVaultSecretName = 'fabricServicePrincipal'

// Scripts for VM custom script extensions
@description('URL of the script for installation of a self-hosted integration runtime')
var shirInstallScriptURL = 'https://raw.githubusercontent.com/Azure/azure-quickstart-templates/master/quickstarts/microsoft.compute/vms-with-selfhost-integration-runtime/gatewayInstall.ps1'

resource vnet 'Microsoft.Network/virtualNetworks@2020-06-01' existing = {
  name: vnetName
  scope: resourceGroup(subscription().id, networkResourceGroupName)
}

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' existing = {
  name: userAssignedIdentityName
  scope: resourceGroup()
}


module sqlDabase '../modules/sqldb.bicep' = {
  name: 'sqlDabase'
  scope: resourceGroup()
  params: {
    databaseName: databaseName
    serverName: '${fullPrefix}-sqlserver'
    databaseSku: sqlDatabaseSKU
    adminGroupObjectId: sqlAdminObjectId
    resourceGroupNameDns: dnsResourceGroupName
    resourceGroupNameNetwork: networkResourceGroupName
    privateLinkVnetName: vnet.name
    privateLinkSubnetName: 'services'
    location: location
    useSampleDatabase: true
    tags: tags
  }
}

/*
module windowsservervm '../modules/virtualMachine.bicep' = {
  name: 'windowsserver'
  scope: resourceGroup()
  params: {
    vmName: 'win-01'
    vmSize: 'Standard_B4as_v2'
    os: 'windowsserver'
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
    networkResourceGroupName: networkResourceGroupName
    vnetName: vnet.name
    subnetName: 'compute'
    location: location
    tags: tags
    initScriptBase64: loadFileAsBase64('winsetup.cmd')
  }
}
*/

module dataFactory '../modules/datafactory.bicep' = {
  name: 'dataFactory'
  scope: resourceGroup()
  params: {
    dataFactoryName: 'contoso-adf'
    location: location
    identityId: userAssignedIdentity.id
    resourceGroupNameDns: dnsResourceGroupName
    resourceGroupNameNetwork: networkResourceGroupName
    privateLinkVnetName: vnet.name
    privateLinkSubnetName: 'services'
  }
}

module keyVault '../modules/keyVault.bicep' = {
  name: 'keyVault'
  scope: resourceGroup()
  dependsOn: [
    dataFactory
  ]
  params: {
    valutName: 'contosodatakv'
    resourcePrefix: resourcePrefix
    location: location
    dnsResourceGroupName: dnsResourceGroupName
    networkResourceGroupName: networkResourceGroupName
    vnetName: vnet.name
    subnetName: 'services'
    secretsReaderObjectId: dataFactory.outputs.dataFactoryManagedIdentity
  }
}

module keyVaultSecret '../modules/keyVaultSecret.bicep' = {
  name: keyVaultSecretName
  scope: resourceGroup()
  dependsOn: [
    keyVault
  ]
  params: {
    keyVaultName: keyVault.outputs.keyVaultName
    secretName: keyVaultSecretName
    secretValue: servicePrincipalSecret
  }
}

module shirVirtualMachine '../modules/virtualMachine.bicep' = {
  name: 'shirVirtualMachine'
  scope: resourceGroup()
  dependsOn: [
    dataFactory
  ]
  params: {
    vmName: 'shir-01'
    vmSize: 'Standard_B4as_v2'
    os: 'windowsserver'
    adminUserName: vmAdminUserName
    adminPassword: vmAdminPwd
    networkResourceGroupName: networkResourceGroupName
    vnetName: vnet.name
    subnetName: 'integration'
    location: location
    tags: tags
  }
}

module shirInstall '../modules/customScriptExtension.bicep' = {
  name: 'shirInstall'
  scope: resourceGroup()
  dependsOn: [
    shirVirtualMachine
    dataFactory
  ]
  params: {
    vmName: 'shir-01'
    location: location
    scriptUrl: shirInstallScriptURL
    command: 'powershell.exe -ExecutionPolicy Unrestricted -File gatewayInstall.ps1 ${dataFactory.outputs.integrationRuntimeKey}'
  }
}

output integrationRuntimeName string = dataFactory.outputs.integrationRuntimeName
output keyVaultName string = keyVault.outputs.keyVaultName
output keyVaultSecretName string = keyVaultSecretName
output dataFactoryCredentialName string = dataFactory.outputs.dataFactoryCredentialName
output sqlServerDnsName string = sqlDabase.outputs.sqlServerDnsName
output databaseName string = databaseName
