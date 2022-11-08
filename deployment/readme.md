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
      "appPrefix": { "value": "contoso" },
      "dnsVmAdminUserName": { "value": "vmadmin" },
      "dnsVmAdminPwd": { "value": "" },
      "tags": {
        "value": {
          "project": "AzIslandNetworking",
          "component": "core"
        }
      }
    }
}
```

Update the following values:

* `dnsVmAdminPwd`: Set this to a random password

Run the following commands to deploy the core infrastructure:

```bash
az login
bicep build core.bicep
az deployment sub create --name core --location centralus --template-file core.json --parameters core.params.json
```

## Deploy Application Infrastructure

In the `deployments` directory, create a new file called `application.params.json` and place the following contents into the file:

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "appPrefix": { "value": "contoso" },
    "sqlAdminLoginName": { "value": "" },
    "sqlAdminLoginPwd": { "value": "" },
    "sqlAdminObjectId": { "value": "" },
    "tags": {
      "value": {
        "appId": "contoso",
        "costCenter": "abc123"
      }
    }
  }
}
```

Update the following values:

- `sqlAdminLoginName`: Set this to the name of an AAD user or group
- `sqlAdminLoginPwd`: Set this to a random password
- `sqlAdminObjectId`: Use the following Azure CLI command to find the object ID of the user of group:

  ```bash
  az ad user show --id <sqlAdminLoginName> --query objectId --out tsv
  ```

Next, run the following command to deploy the data tier:

```bash
bicep build application.bicep
az group create --name contoso-data --location centralus
az deployment group create --resource-group contoso-data --name datatier --template-file application.json --parameters application.params.json
```

## Deploy Application Logic

Because the Function App has been deployed with a Private Link, the Function code must be deployed from within the applicaiton (spoke) virtual network. From the virtual machine deployed to the `desktop` subnet, nagiavte to the location where you cloned the Git repoistory and run the following command from the `function` directory:

```bash
func azure functionapp publish [function_app_name] --typescript
```
