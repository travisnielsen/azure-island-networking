param appName string
param regionCode string
param storageAccountNameSuffix string
param functionAppNameSuffix string

var resourcePrefix = '${appName}-${regionCode}'
var storageResourcePrefix = format('{0}sa', replace(resourcePrefix, '-', ''))
var storageAccountName = substring('${storageResourcePrefix}${storageAccountNameSuffix}', 0, 24)
var functionAppName = '${resourcePrefix}-${functionAppNameSuffix}'

resource appInsights 'Microsoft.Insights/components@2020-02-02' existing = {
  name: '${resourcePrefix}-ai'
}

resource storage 'Microsoft.Storage/storageAccounts@2021-09-01' existing = {
  name: storageAccountName
}

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' existing = {
  name: format('{0}cr', replace(resourcePrefix, '-', ''))
}

resource serviceBus 'Microsoft.ServiceBus/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-sbns'
}

resource eventHub 'Microsoft.EventHub/namespaces@2021-11-01' existing = {
  name: '${resourcePrefix}-ehns'
}

//https://docs.microsoft.com/en-us/azure/azure-functions/functions-identity-based-connections-tutorial

//TODO: This should become a KV reference, but that means dynamically updating the storage account conn string in KV after every deployment
//var storageAccountConnString = '@Microsoft.KeyVault(SecretUri=${kv.properties.vaultUri}/secrets/sbConsumerStorageAccountConnString${regionCode}/)'
var storageAccountConnString = 'DefaultEndpointsProtocol=https;AccountName=${storage.name};AccountKey=${listKeys(storage.id, storage.apiVersion).keys[0].value};EndpointSuffix=${environment().suffixes.storage}'

resource functionApp 'Microsoft.Web/sites@2021-03-01' existing = {
  name: functionAppName

  resource appConfig 'config' = {
    name: 'web'
    properties: {
      appSettings: [
        {
          name: 'APPLICATIONINSIGHTS_CONNECTION_STRING'
          value: 'InstrumentationKey=${appInsights.properties.InstrumentationKey}'
        }
        {
          name: 'AzureWebJobsStorage__accountName'
          value: storage.name
        }
        {
          name: 'FUNCTIONS_EXTENSION_VERSION'
          value: '~4'
        }
        {
          name: 'FUNCTIONS_WORKER_RUNTIME'
          value: 'dotnet'
        }
        {
          name: 'WEBSITE_CONTENTAZUREFILECONNECTIONSTRING'
          value: storageAccountConnString
        }
        {
          name: 'WEBSITE_CONTENTSHARE'
          value: '${toLower(functionApp.name)}-${substring(uniqueString(functionApp.name), 0, 4)}'
        }
        {
          name: 'DOCKER_REGISTRY_SERVER_URL'
          value: 'https://${containerRegistry.name}.azurecr.io'
        }
        {
          name: 'DOCKER_ENABLE_CI'
          value: 'true'
        }
        {
          name: 'WEBSITES_ENABLE_APP_SERVICE_STORAGE'
          value: 'false'
        }
        {
          name: 'ServiceBusHostName'
          value: '${serviceBus.name}.servicebus.windows.net'
        }
        {
          name: 'ServiceBusConnection__fullyQualifiedNamespace'
          value: '${serviceBus.name}.servicebus.windows.net'
        }
        {
          name: 'EhNameSpace__fullyQualifiedNamespace'
          value: '${eventHub.name}.servicebus.windows.net'
        }
        {
          name: 'EhName'
          value: 'poc.customers.addresses'
        }
        {
          name: 'QueueName'
          value: 'poc.customers.addresses'
        }
        {
          name: 'CosmosHost'
          value: 'https://${resourcePrefix}-acdb.documents.azure.com:443/'
        }
        {
          name: 'BaseWeatherUri'
          value: 'https://${resourcePrefix}-as-weather.azurewebsites.net/'
        }
      ]
    }
  }
}
