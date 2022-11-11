param location string
param resourcePrefix string
param role string
param tags object

resource mi 'Microsoft.ManagedIdentity/userAssignedIdentities@2018-11-30' = {
  name: '${resourcePrefix}-mi-${role}'
  location: location
  tags: tags
}
