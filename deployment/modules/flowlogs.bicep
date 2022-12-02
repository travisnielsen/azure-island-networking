param nsgId string
param storageId string
param workspaceId string

param location string
param networkWatcherName string
param flowLogName string

resource nsgFlowLogs 'Microsoft.Network/networkWatchers/flowLogs@2020-06-01' = {
  name: '${networkWatcherName}/${flowLogName}'
  location: location
  properties: {
    targetResourceId: nsgId
    storageId: storageId
    enabled: true
    retentionPolicy: {
      days: 30
      enabled: true
    }
    format: {
      type: 'JSON'
      version: 2
    }
    flowAnalyticsConfiguration: {
      networkWatcherFlowAnalyticsConfiguration: {
        enabled: true
        workspaceResourceId: workspaceId
        trafficAnalyticsInterval: 10
      }
    }
  }
}
