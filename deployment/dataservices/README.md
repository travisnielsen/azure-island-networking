# Scenario 2 - Data Services

## Oveview

The infrastructure in this scenario demonstrates moving data from a privately deployed source system (i.e. inside an Azure VNET) to a Microsoft Fabric Lakehouse usinng Azure Data Factory Self Hosted Integration Runtime (SHIR). This represnts a data movement pattern common at many large enterprises. All outbound traffic from Azure is filtered through a common egress point: Azure Firewall in this case. Use the instructions below to deploy this scenario in order to validate and examine the details.

## Deployment

> [!NOTE]
> It is assumed you have administraitve access to a workspace deployed to a Microsoft Fabric instance that is associated with the same tenant as your Azure environment.
> The deployment scripts used in this section configure access control based on Entra ID groups. It is assumed the account being used for deployment has permissions to read the Entra ID directory, manage group membership, and create Service Principals.

### Configure Entra ID

First, create an Entra ID group to be used for providing administrative access to the SQL server deployed in this topology. Open the Azure Portal and navigate to **Microsoft Entra ID** > **Groups** and click the **New group** button. Name the group `sqladmins` (or similar) and accept the default group type (security) and membership type (assigned).

### Configure Fabric

Next, navigate to your Microsoft Fabric environment and document the the target Workspace and Lakehouse (artifact) IDs. This is done by selecting the Lakehouse and copying the values from the URL. Example: `https://app.fabric.microsoft.com/groups/[WORKSPACE_ID]/lakehouses/[ARTIFACT_ID]?experience=data-engineering`. This information will be used by the configuration scripts for the Lakehouse Linked Service in Data Factory.

Ensure your Fabric environment is configured to allow Service Principal Authentication via the **Tenant Settings** in the Admin Portal. This needs to be set in two places in the **Developer Settings** section: *Allow service principals to use Power BI APIs* and *Allow service principals to create and use profiles*. For details, see: [OneLake Security: Authentication](https://learn.microsoft.com/en-us/fabric/onelake/onelake-security#authentication).

### Deployment Script

In the `/deployments/dataservices` directory, create a new file called `dataservices.params.json` and place the following contents into the file and update the value for the `vmAdminPwd` parameter based on your environment.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
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

Next, create a new file called `datafactory.params.json` and place the following contents into the file. Update the values for the `fabricWorkspaceId` and `fabricArtifactId` parameters based on the Fabric workspace information identfied in the previous steps above.

```json
{
  "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#",
  "contentVersion": "1.0.0.0",
  "parameters": {
    "fabricWorkspaceId": { "value": "" },
    "fabricArtifactId": { "value": "" }
  }
}

```

Next, run the following PowerShell script to deploy the data services.

```powershell
.\deploy--dataservices.ps1 centralus contoso dataservices
```

After the deployment completes, use the **Manage Access** section in your Fabric Workspace to grant access to the Service Principal created by the deployment script. The default name of the Service Principal is `contoso-dataservices-adf-fabric`. Detailed instructions can be found here: [Set up Microsoft Fabric](https://learn.microsoft.com/en-us/azure/iot-operations/connect-to-cloud/howto-configure-destination-fabric#set-up-microsoft-fabric).
