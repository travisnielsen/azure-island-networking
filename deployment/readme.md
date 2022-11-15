# Deployment

The referece design is composed of three tiers:

* *Core infrastruture*, which includes the network (topology, traffic segmentation, egress), end-user compute environment, and a secure configuration baseline via Azure Policy.

* *Application infrastructure*, which includes all Azure resources used for hosting and processing data

* *Application logic*, which includes arficats for data schemas, code, and workflows that run on the application infrastructure

The configuration and deployment core and application infrsatructure is accomplished via Azure Bicep files, which can be deployed to a subscritpion with the Azure CLI on a desktop or an Azure DevOps pipeline.

## Deploy Baseline Policies

TBD

## Deploy Core Infrastructure

In the `deployments` directory, create a new file called `core.params.json` and place the following contents into the file:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "region": { "value": "centralus"},
      "orgPrefix": { "value": "contoso" },
      "appPrefix": { "value": "core" },
      "vmAdminUserName": { "value": "vmadmin" },
      "vmAdminPwd": { "value": "" },
      "tags": {
        "value": {
          "project": "AzIslandNetworking",
          "component": "core"
        }
      }
    }
 }
```

Update these parameters to fit your environment. Be sure to set the value of `vmAdminPwd` to a random value.

Next, run the following commands to deploy the core infrastructure:

```powershell
.\deploy-core.ps1 centralus contoso core
```

## Deploy Application (Island) Infrastructure

In the `deployments` directory, create a new file called `application-base.params.json` and place the following contents into the file:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "region": { "value": "centralus"},
    "orgPrefix": { "value": "contoso" },
    "appPrefix": { "value": "island" },
    "coreResourcePrefix": { "value": "contoso-core-cus" },
    "coreNetworkRgName": { "value": "contoso-core-network" },
    "coreDnsRgName": { "value": "contoso-core-dns" },
    "vmAdminUserName": { "value": "vmadmin" },
    "vmAdminPwd": { "value": "" },
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

```bash
.\deploy-application-base.ps1 centralus contoso island
```

## Deploy the Application (island) Workload

TBD
