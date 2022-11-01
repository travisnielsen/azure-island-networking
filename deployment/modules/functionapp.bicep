param name string
param appInsightsKey string
param workerRuntime string
param resourceGroupNameNetwork string
param vnetName string
param subnetNameIntegration string
param subnetNamePrivateEndpoint string
param storageAccountNameData string
param storageAccountIdData string
param storageAccountApiVersionData string
param appTags object

var subscriptionId = subscription().subscriptionId

// App Service Plan
resource appService 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: name
  location: resourceGroup().location
  kind: 'elastic'
  sku: {
    name: 'EP1'
    tier: 'ElasticPremium'
  }
  properties: {
    maximumElasticWorkerCount: 20
  }
  tags: appTags
}

// Storage Account for the Function App
// TODO: Add automation for this: https://docs.microsoft.com/en-us/azure/azure-functions/functions-networking-options#restrict-your-storage-account-to-a-virtual-network-preview
resource storageAccountFunc 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: '${name}functemp'
  location: resourceGroup().location
  sku: {
    name: 'Standard_LRS'
    tier: 'Standard'
  }
  kind: 'StorageV2'
  properties: {
    supportsHttpsTrafficOnly: true
    accessTier: 'Hot'
  }
  tags: appTags
}

// Function App
resource functionApp 'Microsoft.Web/sites@2020-06-01' = {
  name: name
  location: resourceGroup().location
  kind: 'functionapp'
  properties: {
    enabled: true
    hostNameSslStates: [
      {
        name: '${name}.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
      {
        name: '${name}.scm.azurewebsites.net'
        sslState: 'Disabled'
        hostType: 'Standard'
      }
    ]
    serverFarmId: appService.id
    siteConfig: {
      appSettings: [
        {
          name: 'AzureWebJobsStorage'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountFunc.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountFunc.id, storageAccountFunc.apiVersion).keys[0].value}'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountFunc.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountFunc.id, storageAccountFunc.apiVersion).keys[0].value}'
        }
        {
          name: 'StorageAccountData'
          value: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountNameData};EndpointSuffix=${environment().suffixes.storage};AccountKey=${listKeys(storageAccountIdData, storageAccountApiVersionData).keys[0].value}'
        }
        {
          name: 'APPINSIGHTS_INSTRUMENTATIONKEY'
          value: appInsightsKey
        }
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsightsKey}'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: workerRuntime
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~3'
        }
        {
          name: 'WEBSITE_NODE_DEFAULT_VERSION'
          value: '~12'
        }
      ]
    }
    httpsOnly: true
  }
  tags: appTags
}

// Function Network Config
resource functionNetworkConfig 'Microsoft.Web/sites/networkConfig@2020-06-01' = {
  name: '${functionApp.name}/virtualNetwork'
  dependsOn: [
    functionApp
  ]
  properties: {
    subnetResourceId: resourceId(subscriptionId, resourceGroupNameNetwork, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetNameIntegration)
  }
}

module functionPrivateEndpoint 'privateendpoint.bicep' = {
  name: 'function-privateEndpoint'
  dependsOn: [
    functionApp
  ]
  params: {
    privateEndpointName: '${functionApp.name}-functionendpoint'
    serviceResourceId: functionApp.id
    dnsZoneName: 'privatelink.azurewebsites.net'
    resourceGroupNameNetwork: resourceGroupNameNetwork
    vnetName: vnetName
    subnetName: subnetNamePrivateEndpoint
    // subnetId: resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetNamePrivateEndpoint)
    // dnsZoneId: resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/privateDnsZones', 'privatelink.azurewebsites.net' )
    groupId: 'sites'
  }
}

// Function App Config
/*
resource functionAppConfig 'Microsoft.Web/sites/config@2020-06-01' = {
  name: '${functionApp.name}/web'
  properties: {
    numberOfWorkers: -1
    defaultDocuments: [
      'Default.htm'
      'Default.html'
      'Default.asp'
      'index.htm'
      'index.html'
      'iisstart.htm'
      'default.aspx'
      'index.php'
      'hostingstart.html'
    ]
    netFrameworkVersion: 'v4.0'
    phpVersion: '5.6'
    requestTracingEnabled: false
    remoteDebuggingEnabled: false
    httpLoggingEnabled: false
    logsDirectorySizeLimit: 35
    detailedErrorLoggingEnabled: false
    publishingUsername: '$${functionAppName}'
    azureStorageAccounts: {}
    scmType: 'None'
    use32BitWorkerProcess: true
    webSocketsEnabled: false
    alwaysOn: false
    managedPipelineMode: 'Integrated'
    virtualApplications: [
      {
        virtualPath: '/'
        physicalPath: 'site\\wwwroot'
        preloadEnabled: true
      }
    ]
    loadBalancing: 'LeastRequests'
    experiments: {
      rampUpRules: []
    }
    autoHealEnabled: false
    cors: {
      allowedOrigins: [
        'https://functions.azure.com'
        'https://functions-staging.azure.com'
        'https://functions-next.azure.com'
      ]
      supportCredentials: false
    }
    localMySqlEnabled: false
    ipSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictions: [
      {
        ipAddress: 'Any'
        action: 'Allow'
        priority: 1
        name: 'Allow all'
        description: 'Allow all access'
      }
    ]
    scmIpSecurityRestrictionsUseMain: false
    http20Enabled: true
    minTlsVersion: '1.2'
    ftpsState: 'AllAllowed'
    PreWarmedInstanceCount: 0
  }
  tags: appTags
}
*/

// Function App Binding
/*
resource functionAppBinding 'Microsoft.Web/sites/hostNameBindings@2020-06-01' = {
  name: '${functionApp.name}/${functionApp.name}.azurewebsites.net'
  properties: {
    siteName: functionApp.name
    hostNameType: 'Verified'
  }
}
*/
