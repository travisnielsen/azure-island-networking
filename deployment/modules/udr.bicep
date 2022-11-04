param name string
param azFwlIp string
param location string

resource route 'Microsoft.Network/routeTables@2020-06-01' = {
  name: name
  location: location
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      {
        name: 'DefaultRoute'
        properties: {
          addressPrefix: '0.0.0.0/0'
          nextHopType: 'VirtualAppliance'
          nextHopIpAddress: azFwlIp
        }
      }
    ]
  }
}

output id string = route.id
