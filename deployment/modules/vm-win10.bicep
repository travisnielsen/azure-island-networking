param vmName string
param networkResourceGroupName string
param vnetName string
param subnetName string
param adminUserName string

@secure()
param adminPassword string

/* Was throwing a bicep warning because it wasn't being used
@allowed([
  'win10'
  'linux'
])
@description('The type of VM: Windows 10 or Linux.')
param os string = 'win10'
*/

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2_v3'

@description('location for all resources')
param location string

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
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsDesktop'
        offer: 'Windows-10'
        sku: '20h2-pro'
        version: 'latest'
      }
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
