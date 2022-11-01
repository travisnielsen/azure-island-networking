param dnsZone string
param appName string
param alias string

resource frontdoorcname 'Microsoft.Network/privateDnsZones/CNAME@2020-06-01' = {
  name: '${dnsZone}/${appName}'
  properties: {
    ttl: 3600
    cnameRecord: {
      cname: alias
    }
  }
}