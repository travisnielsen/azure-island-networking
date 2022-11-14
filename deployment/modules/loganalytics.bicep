param name string
param location string

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2020-08-01' = {
  name: name
  location: location
  properties: {
    retentionInDays: 30
    sku: {
      name: 'PerGB2018'
    }
  }
}

output id string = logAnalytics.id
