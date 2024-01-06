param vmName string
param scriptUrl string
param command string
param location string = resourceGroup().location

resource vm 'Microsoft.Compute/virtualMachines@2023-09-01' existing = {
  name: vmName
  scope: resourceGroup()
}

resource customScriptExtension 'Microsoft.Compute/virtualMachines/extensions@2023-09-01' = {
  name: 'selfHostedIntegrationRuntime'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Compute'
    type: 'CustomScriptExtension'
    typeHandlerVersion: '1.10'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        scriptUrl
      ]
    }
    protectedSettings: {
      commandToExecute: command
    }
  }
}
