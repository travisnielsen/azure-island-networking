param vmName string
param networkResourceGroupName string
param vnetName string
param subnetName string
param adminUserName string
@secure()
param adminPassword string
@description('Size of the virtual machine.')
param vmSize string
@description('location for all resources')
param location string = resourceGroup().location
@description('Base64 encocded string to be run at VM startup')
param initScriptBase64 string = ''

@allowed([
  'windows10'
  'linux'
])
param os string

var linuxImage = {
  publisher: 'Canonical'
  offer: 'UbuntuServer'
  sku: '22.04-LTS'
  version: 'latest'
}

var windows10Image = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-10'
  sku: '20h2-pro'
  version: 'latest'
}

var linuxConfiguration = {
  disablePasswordAuthentication: false
}

var subscriptionId = subscription().subscriptionId
var nicName = '${vmName}-nic'

resource nInter 'Microsoft.Network/networkInterfaces@2020-06-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId(subscriptionId, networkResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
          }
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2020-06-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
      linuxConfiguration: (os =~ 'linux') ? linuxConfiguration : null
      customData: ( !empty(initScriptBase64) ? initScriptBase64 : null )
    }
    storageProfile: {
      imageReference: (os =~ 'linux') ? linuxImage : windows10Image
      osDisk: {
        name: '${vmName}-os'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          name: '${vmName}-dataDisk'
          diskSizeGB: 1023
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nInter.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
        // storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}

/*
resource aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = {
  name: '${vm.name}/AADLoginForWindows'
  location: location
  dependsOn: [
    vm
  ]
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: ''
    autoUpgradeMinorVersion: true

  }
}
*/

resource autoShutdown 'Microsoft.DevTestLab/schedules@2016-05-15' = {
  name: 'shutdown-computevm-${vm.name}'
  location: location
  properties: {
    status: 'Enabled'
    taskType: 'ComputeVmShutdownTask'
    dailyRecurrence: {
      time: '0000'
    }
    timeZoneId: 'Central Standard Time'
    notificationSettings: {
      status: 'Disabled'
      timeInMinutes: 30
    }
    targetResourceId: vm.id
  }
}

output vmId string = vm.id
