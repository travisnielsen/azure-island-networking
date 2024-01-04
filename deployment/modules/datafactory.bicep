param dataFactoryName string
param location string = resourceGroup().location
param resourceGroupNameDns string
param resourceGroupNameNetwork string
param privateLinkVnetName string
param privateLinkSubnetName string
param integrationRuntimeSubnetId string


resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' = {
  name: dataFactoryName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    publicNetworkAccess: 'Disabled'
    /*
    repoConfiguration: {
      type: 'FactoryVSTSConfiguration'
      accountName: ''
      projectName: ''
      repositoryName: ''
      collaborationBranch: ''
      rootFolder: ''
    }
    */
  }
}


resource integrationRuntime 'Microsoft.DataFactory/factories/integrationRuntimes@2018-06-01' = {
  name: '${dataFactoryName}-integrationRuntime'
  parent: dataFactory
  properties: {
    type: 'Managed'
    typeProperties: {
      computeProperties: {
        location: 'AutoResolve'
      }
      customerVirtualNetwork: {
        subnetId: integrationRuntimeSubnetId
      }
    }
  }
}

module privateEndpoint 'privateendpoint.bicep' = {
  name: '${dataFactory.name}-privateendpoint'
  params: {
    location: location
    privateEndpointName: '${dataFactory.name}-endpoint'
    serviceResourceId: dataFactory.id
    dnsZoneName: 'privatelink.datafactory.azure.net'
    dnsResourceGroupName: resourceGroupNameDns
    networkResourceGroupName: resourceGroupNameNetwork
    vnetName: privateLinkVnetName
    subnetName: privateLinkSubnetName
    groupId: 'dataFactory'
  }
}


// TODO: need to finsih configuration
/*
resource privateLink 'Microsoft.DataFactory/factories/managedVirtualNetworks/managedPrivateEndpoints@2018-06-01' = {
  name: '${name}/something'
  properties: {

  }
}
*/

output id string = dataFactory.id
output name string = dataFactory.name
