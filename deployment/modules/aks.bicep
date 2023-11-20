param resourcePrefix string
param location string
param linuxAdminUsername string = 'adminUser'
param subnetId string
param keyData string


resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'aksMi'
  location: location
}


resource aks 'Microsoft.ContainerService/managedClusters@2023-09-01' = {
  name: '${resourcePrefix}-aks'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${mi.id}': {}
    }
  }
  properties: {
    dnsPrefix: '${resourcePrefix}-aks-dns'
    agentPoolProfiles: [
      {
        name: 'agentpool'
        count: 1
        vmSize: 'Standard_B4ms'
        osDiskSizeGB: 128
        osDiskType: 'Managed'
        vnetSubnetID: subnetId
        maxCount: 5
        minCount: 1
        enableAutoScaling: true
        enableNodePublicIP: false
        mode: 'System'       
        osType: 'Linux'
      }
    ]
    networkProfile: {
      loadBalancerSku: 'Standard'
      networkPlugin: 'azure'
      networkDataplane: 'azure'
      networkPolicy: 'azure'
    }
    nodeResourceGroup: '${resourcePrefix}-aks-node'
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: keyData
          }
        ]
      }
    }
  }
}
