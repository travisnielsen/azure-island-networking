param actionGroupName string
param actionGroupShortName string

resource actionGroup 'Microsoft.Insights/actionGroups@2018-03-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    smsReceivers: []
    webhookReceivers: []
    groupShortName: actionGroupShortName
    enabled: true
    emailReceivers: [
      {
        name: 'wbaDemoAdmin'
        emailAddress: 'ernest.oshokoya@microsoft.com'
      }
    ]
  }
}

output name string = actionGroup.name
output id string = actionGroup.id
