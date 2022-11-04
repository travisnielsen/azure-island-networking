param vmssName string = 'DevopsBuildAgentScaleSet'
param vnetResourceGroupName string
param subnetName string
param vnetName string
param location string
param adminUserName string
@secure()
param adminPassword string

var subscriptionId = subscription().subscriptionId

resource virtualMachineScaleSet 'Microsoft.Compute/virtualMachineScaleSets@2020-06-01' = {
  name: vmssName
  location: location
  sku: {
    name: 'Standard_D2s_v3'
    tier: 'Standard'
    capacity: 0
  }
  properties: {
    singlePlacementGroup: true
    upgradePolicy: {
      mode: 'Manual'
    }
    scaleInPolicy: {
      rules: [
        'Default'
      ]
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'devopsbui'
        adminUsername: adminUserName
        adminPassword: adminPassword
          linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
        secrets: []
      }
      storageProfile: {
        osDisk: {
          osType: 'Linux'
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Premium_LRS'
          }
          diskSizeGB: 30
        }
        imageReference: {
          publisher: 'Canonical'
          offer: 'UbuntuServer'
          sku: '18.04-LTS'
          version: 'latest'
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'contoso-hub-nic01'
            properties: {
              primary: true
              enableAcceleratedNetworking: false
              dnsSettings: {
                dnsServers: []
              }
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'contoso-hub-nic01-defaultIpConfiguration'
                  properties: {
                    primary: true
                    subnet: {
                      id: resourceId(subscriptionId, vnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', vnetName, subnetName)
                    }
                    privateIPAddressVersion: 'IPv4'
                  }
                }
              ]
            }
          }
        ]
      }
      diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
      extensionProfile: {
        extensions: []
      }
      priority: 'Regular'
    }
    overprovision: false
    doNotRunExtensionsOnOverprovisionedVMs: false
    platformFaultDomainCount: 5
  }
}
