param resourcePrefix string
param location string
param linuxAdminUsername string = 'adminUser'
param subnetId string

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: 'aksMi'
  location: location
}

resource aks 'Microsoft.ContainerService/managedClusters@2022-07-01' = {
  name: '${resourcePrefix}-aks'
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: mi
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
    nodeResourceGroup: '${resourcePrefix}-aks-rg'
    linuxProfile: {
      adminUsername: linuxAdminUsername
      ssh: {
        publicKeys: [
          {
            keyData: 'ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDtPdj2xybFn5D3gNiZV7Ys+Nj3IRZfdM0+W68DRqfNvw7e4SkiS4Tm92i3mX85Odqiag+Q4bV0DArrlHXiYf/nhQLtc9ILVGHmzBFMwhsb425D9ycCwaP+uH+1+MRt7N2MR9Pts64KWX9SqSr3GEbHuwisScvNfXEJJFPKdmKVJFQ9092wjxq1QFj9AFAafZKIONSQIowEBg8eJWp+a8d7UQ7OtV7UVC4zd71Zo6TKNziLIjI+jt1FG2Siku9kxl2Yu4d/RY02I8diKpzwVL/2gutwLiEEwmNokkD6rsLe+5IBHMmeXYZAdB3hGrgFt7NkOKFLD570hL/JxZy5/irSFUMd4N0nb6viU1+n6yRzzz+QRhtxu8lad39ceFk9B6LlHOeKqDHRpH7hhNJ/ALpORo7fEXme6E6uGouNEEJ/JwwKlFzU+WcfogkEVQvWIzm8uqjImCT+/tHTM5kbwC8uNRjK44rvJ6VuQl/qvA9LZaU21X/TYz+5tbyCX9TVNIeKmnK1TKkYKu24jhYsKafpmAu33S4LXQKnXdqn18Bd2IBE487ohQph6RUAqFzT+UlQ1YzjzHN6YU474V6W2z4VJRy5bE3yvPKrGn5UavF5PnKChqcbq6X9gcgvs1flAQaBKuiajf+ai8+tInF6Mq3jf2ovlS4vwAlWf8WVqy/94Q== mike@cc-16b3-e82e0253-7b84f88bc-6vqd8'
          }
        ]
      }
    }
  }
}
