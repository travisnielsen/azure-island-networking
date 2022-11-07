param location string
param resourcePrefix string
var acrName = format('{0}acr', replace(resourcePrefix, '-', ''))

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2021-09-01' = {
  name: acrName
  location: location
  sku: {
    name:'Premium'
  }
}
