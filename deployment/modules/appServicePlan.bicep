param location string
param resourcePrefix string
param appNameSuffix string

@allowed([
  'Windows'
  'Linux'
])
param serverOS string = 'Windows'

param zoneRedundant bool
param skuName string 
param skuTier string

resource appServicePlan 'Microsoft.Web/serverfarms@2021-03-01' = {
  name: '${resourcePrefix}-asp-${appNameSuffix}'
  kind: serverOS == 'Windows' ? '' : 'linux'
  location: location
  properties: {
    zoneRedundant: zoneRedundant
    reserved: serverOS == 'Linux'
    maximumElasticWorkerCount: 20
  }
  sku: {
    name: skuName
    tier: skuTier
    capacity: zoneRedundant ? 3 : 1
  }
}

output resourceId string = appServicePlan.id
