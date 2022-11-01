param zoneName string

resource dnsZone 'Microsoft.Network/privateDnsZones@2018-09-01' = {
  name: zoneName
  location: 'global'
}

output id string = dnsZone.id