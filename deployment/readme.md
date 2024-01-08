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
      "region": { "value": "centralus"},
      "orgPrefix": { "value": "contoso" },
      "appPrefix": { "value": "core" },
      "deployBridge": { "value:" true },
      "deployVnetGateway": { "value": false },
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

The infrastructure in this scenario demonstrates moving data from a privately deployed source system (i.e. inside an Azure VNET) to a Microsoft Fabric Lakehouse usinng Azure Data Factory Self Hosted Integration Runtime (SHIR). This represnts a data movement pattern common at many large enterprises. All outbound traffic from Azure is filtered through a common egress point: Azure Firewall in this case. Use the instructions below to deploy this scenario in order to validate and examine the details.

> [!NOTE]
> It is assumed you have administraitve access to a workspace deployed to a Microsoft Fabric instance that is associated with the same tenant as your Azure environment.
> The deployment scripts used in this section configure access control based on Entra ID groups. It is assumed the account being used for deployment has permissions to read the Entra ID directory, manage group membership, and create Service Principals.

First, create an Entra ID group to be used for providing administrative access to the SQL server deployed in this topology. Open the Azure Portal and navigate to **Microsoft Entra ID** > **Groups** and click the **New group** button. Name the group `sqladmins` (or similar) and accept the default group type (security) and membership type (assigned).

Next, navigate to your Microsoft Fabric environment and document the the target Workspace and Lakehouse (artifact) IDs. This is done by selecting the Lakehouse and copying the values from the URL. Example: `https://app.fabric.microsoft.com/groups/[WORKSPACE_ID]/lakehouses/[ARTIFACT_ID]?experience=data-engineering`. This information will be used by the configuration scripts for the Lakehouse Linked Service in Data Factory.

Ensure your Fabric environment is configured to allow Service Principal Authentication via the **Tenant Settings** in the Admin Portal. This needs to be set in two places in the **Developer Settings** section: *Allow service principals to use Power BI APIs* and *Allow service principals to create and use profiles*. For details, see: [OneLake Security: Authentication](https://learn.microsoft.com/en-us/fabric/onelake/onelake-security#authentication).


In the `deployments` directory, create a new file called `dataservices.params.json` and place the following contents into the file:

```json
{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {
      "fabricWorkspaceId": { "value": "" },
      "fabricArtifactId": { "value": "" },
      "vmAdminUserName": { "value": "vmadmin" },
      "vmAdminPwd": { "value": "" },
      "tags": {
        "value": {
          "project": "ContosoDemo",
          "component": "Data"
        }
      }
    }
 }
```

Be sure to update the values for the `fabricWorkspaceId`, `fabricArtifactId`, and `vmAdminPwd` parameters. Next, run the following PowerShell script to deploy the data services.

```powershell
.\deploy-05-dataservices.ps1 centralus contoso dataservices
```

After the deployment completes, use the **Manage Access** section in your Fabric Workspace to grant access to the Service Principal created by the deployment script. The default name of the Service Principal is `contoso-dataservices-adf-fabric`. Detailed instructions can be found here: [Set up Microsoft Fabric](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/howto-configure-destination-fabric#set-up-microsoft-fabric).
