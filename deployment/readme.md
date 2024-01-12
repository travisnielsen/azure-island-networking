# Deployment

The referece design is composed of three tiers:

* *Core infrastruture*, which includes the network (topology, traffic segmentation, egress), end-user compute environment, and a secure configuration baseline via Azure Policy.

* *Application infrastructure*, which includes all Azure resources used for hosting and processing data

* *Application logic*, which includes arficats for data schemas, code, and workflows that run on the application infrastructure

The configuration and deployment core and application infrsatructure is accomplished via Azure Bicep files, which can be deployed to a subscritpion with the Azure CLI on a desktop or an Azure DevOps pipeline.

## Environment Setup

These instructions assume the following are installed on your workstation:

* [PowerShell](https://learn.microsoft.com/en-us/powershell/scripting/install/installing-powershell?view=powershell-7.3)
* [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli)
* [Azure Bicep](https://learn.microsoft.com/en-us/azure/azure-resource-manager/bicep/bicep-cli#install)

Use the following Azure CLI command to sign in and connect to your target subscription:

```powershell
az login
az account set --subscrption [your_subscription_id]
```

This sample invovles multiple layers of infrastructure. Use the following sections to deploy each part based on your needs.

## Deploy Baseline Policies

TBD

## Deploy Core Infrastructure

In the `deployments` directory, create a new file called `core.params.json` and place the following contents into the file:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "deployBridge": { "value": true },
      "deployVnetGateway": { "value": false },
      "vmAdminUserName": { "value": "vmadmin" },
      "vmAdminPwd": { "value": "" },
      "vmSize": { "value": "Standard_B2as_v2" },
      "tags": {
        "value": {
          "project": "AzIslandNetworking",
          "component": "core"
        }
      }
    }
 }
```

Update these parameters to fit your environment. Be sure to set the value of `vmAdminPwd` to a random value. In addtion, the values for the `deployBridge` and `deployVnetGateway` parameters will default to *false* unless otherwise specified.

Next, run the following command to deploy the core infrastructure (hub and spoke only):

```powershell
.\deploy-01-core.ps1 centralus contoso core
```

## Deploy Workload Scenarios

This repo includes scripts for deploying two optional scenarios. Deployment steps for each are documented in the following sections.

### Scenario 1: Application Infrastructure (Island)

In the `deployments` directory, create a new file called `app-base.params.json` and place the following contents into the file:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "region": { "value": "[your_region_name]"},
    "orgPrefix": { "value": "contoso" },
    "appPrefix": { "value": "island" },
    "vmAdminUserName": { "value": "vmadmin" },
    "vmAdminPwd": { "value": "" },
    "vmSizeUtilityServer": { "value": "Standard_B2as_v2" },
    "tags": {
      "value": {
        "project": "AzIslandNetworking",
        "component": "island"
      }
    }
  }
}
```

Update these parameters to fit your environment. Be sure to set the value of `vmAdminPwd` to a random value.

Next, run the following command to deploy the application core infrastructure:

```powershell
.\deploy-02-appbase.ps1 [your_region_name] contoso island
```

When completed, proceed to deploy the application infrastructure.

This sample includes a small AKS cluster that requires an SSH key. Generate the key using the following command:

```bash
ssh-keygen -t rsa -b 4096
```

Next, run the following command to deploy the application services for the sample workload:

```powershell
.\deploy-03-appsvc.ps1 [your_region_name] contoso island 'ssh rsa AAAAB3NzaC1yc ...'
```

Make sure to replace the value of the SSH key with the output from the `ssh-keygen` command.

### Scenario 2: Data Infrastrucure (Spoke)

See the documentation in the [Data Services Scenario](/deployment/dataservices/README.md) for deployment instructions.
