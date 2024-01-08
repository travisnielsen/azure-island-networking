param linkedServiceName string
param dataFactoryName string
param valutUri string

resource dataFactory 'Microsoft.DataFactory/factories@2018-06-01' existing = {
  name: dataFactoryName
  scope: resourceGroup()
}

resource linkedService 'Microsoft.DataFactory/factories/linkedservices@2018-06-01' = {
  name: linkedServiceName
  parent: dataFactory
  properties: {
    type: 'AzureKeyVault'
    typeProperties: {
      baseUrl: valutUri
    }
  }
}

output linkedServiceName string = linkedService.name
