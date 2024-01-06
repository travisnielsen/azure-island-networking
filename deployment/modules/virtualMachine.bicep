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
param tags object = {}

@allowed([
  'windowsserver'
  'linux'
])
param os string

var osType = os =~ 'linux' ? 'linux' : 'windows'

var linuxImage = {
  publisher: 'canonical'
  offer: '0001-com-ubuntu-server-focal'
  sku: '20_04-lts-gen2'
  version: 'latest'
}

/*
var windows11Image = {
  publisher: 'MicrosoftWindowsDesktop'
  offer: 'Windows-11'
  sku: 'win11-23h2-pro'
  version: 'latest'
}
*/

var windowsServerImage = {
  publisher: 'MicrosoftWindowsServer'
  offer: 'WindowsServer'
  sku: '2022-datacenter-azure-edition-hotpatch'
  version: 'latest'
}

var linuxConfiguration = {
  disablePasswordAuthentication: false
}

var subscriptionId = subscription().subscriptionId
var nicName = '${vmName}-nic'

resource nic 'Microsoft.Network/networkInterfaces@2022-11-01' = {
  name: nicName
  location: location
  tags: tags
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
    enableAcceleratedNetworking: true
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2022-11-01' = {
  name: vmName
  location: location
  tags: tags
  identity: {
    type: 'SystemAssigned'
  }
  zones: [
    '1'
  ]
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUserName
      adminPassword: adminPassword
      linuxConfiguration: (os =~ 'linux') ? linuxConfiguration : null
      customData: (!empty(initScriptBase64) && osType == 'linux') ? initScriptBase64 : null
    }
    storageProfile: {
      imageReference: (os =~ 'linux') ? linuxImage : windowsServerImage
      osDisk: {
        name: '${vmName}-os'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        deleteOption: 'Delete'
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
          id: nic.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
        // storageUri: stg.properties.primaryEndpoints.blob
      }
    }
    userData: (!empty(initScriptBase64) && osType == 'windows') ? initScriptBase64 : null
    
  }
}

resource aadextension 'Microsoft.Compute/virtualMachines/extensions@2020-06-01' = if(os =~ 'windows11' || os =~ 'windowsserver') {
  name: '${vm.name}-AADLoginForWindows'
  parent: vm
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
  }
}

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

output id string = vm.id
output privateIPAddress string = nic.properties.ipConfigurations[0].properties.privateIPAddress
