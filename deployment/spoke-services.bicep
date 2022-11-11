param appPrefix string
param orgPrefix string
param regionCode string
param location string = resourceGroup().location
param workloadVnetName string
param workloadVnetResourceGroupName string
param webVmAdminUserName string = 'dnsadmin'
@secure()
param webVmAdminPwd string
param webVmSubnetName string

var resourcePrefix = '${orgPrefix}-${appPrefix}-${regionCode}'

// web server hosting http://api.contoso.com
module webServer 'modules/virtualMachine.bicep' = {
  name: 'web-server-consoso-com'
  params: {
    adminUserName: webVmAdminUserName
    adminPassword: webVmAdminPwd
    networkResourceGroupName: workloadVnetResourceGroupName
    location: location
    vnetName: workloadVnetName
    subnetName: webVmSubnetName
    os: 'linux'
    vmName: '${resourcePrefix}-web01'
    vmSize: 'Standard_B2ms'
    initScriptBase64: loadFileAsBase64('webserver.yml')
  }
}
