param name string
param securityRules array
param networkWatcherName string
param location string

resource storageAccount 'Microsoft.Storage/storageAccounts@2020-08-01-preview' = {
  name: uniqueString(resourceGroup().id)
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'StorageV2'
  properties: {
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: uniqueString(resourceGroup().id)
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

resource spokensg 'Microsoft.Network/networkSecurityGroups@2020-06-01' = {
  name: name
  location: location
  properties: {
    securityRules: securityRules
  }
}

module flowLogs 'flowlogs.bicep' = {
  name: spokensg.name
  scope: resourceGroup('NetworkWatcherRG')
  params: {
    networkWatcherName: networkWatcherName
    flowLogName: name
    nsgId: spokensg.id
    location: location
    storageId: storageAccount.id
    workspaceId: logAnalytics.id
  }
}

output id string = spokensg.id
output nsgName string = spokensg.name
