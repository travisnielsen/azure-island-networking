$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$orgPrefix = $Args[1]
$appPrefix = $Args[2]

switch ($location) {
    'eastus' {
        $regionCode = 'eus'
    }
    'eastus2' {
        $regionCode = 'eus2'
    }
    'centralus' {
        $regionCode = 'cus'
    }
    'westus' {
        $regionCode = 'wus'
    }
    'westus2' {
        $regionCode = 'wus2'
    }
    'westus3' {
        $regionCode = 'wus3'
    }
    'northcentralus' {
        $regionCode = 'ncus'
    }

    Default {
        throw "Invalid Target Location Specified"
    }
}

$resourceGroupName = "$orgPrefix-$appPrefix"
az group create --name $resourceGroupName --location $location

# create Service Principal for ADF to use for accessing the Fabric Lakehouse

$servicePrincipalName = "$orgPrefix-dataservices-adf-fabric"

Write-Host "Looking for Service Principal: $servicePrincipalName" -ForegroundColor Cyan
$sp = Get-AzADServicePrincipal -DisplayName $servicePrincipalName
$servicePrincipalAppId = ''
$servicePrincipalSecret = ''
$updateServicePrincipalSecret = $false

if ($sp) {
    Write-Host "Service Principal found. Using existing Service Principal" -ForegroundColor Yellow
    $servicePrincipalAppId = $sp.AppId
    Write-Host "Service Principal App ID: $servicePrincipalAppId" -ForegroundColor Cyan
} else {
    Write-Host "Creating Service Principal: $servicePrincipalName. This will be used by Data Factory for accessing the Fabric Lakehouse" -ForegroundColor Cyan
    $sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName
    $servicePrincipalAppId = $sp.AppId
    $servicePrincipalSecret = $sp.PasswordCredentials.SecretText
    $updateServicePrincipalSecret = $true
    Write-Host "Service Principal App ID: $servicePrincipalAppId" -ForegroundColor Cyan
}

Write-Host ""

# create the user assigned identity for the ADF instance and assign it to the SQL Admins group
# NOTE: This is idempotent and secrets are not involved, so we do not need to check if the identity already exists

$userAssignedIdentityName = 'contoso-dataservices-adf'
Write-Host "Setting up Data Factory User Assigned Managed Identity: $userAssignedIdentityName" -ForegroundColor Cyan
New-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $userAssignedIdentityName -Location $location
$adfIdentityObjectId = Get-AzUserAssignedIdentity -ResourceGroupName $resourceGroupName -Name $userAssignedIdentityName | Select-Object -ExpandProperty 'PrincipalId'
Write-Host "ADF Identity Object ID: $adfIdentityObjectId" -ForegroundColor Cyan
$sqlAdminGroup = Get-AzADGroup -DisplayName "sqladmins"
$sqlAdminsObjectId = $sqlAdminGroup.Id
Write-Host "SQL Admins Group Object ID: $sqlAdminsObjectId" -ForegroundColor Cyan
Write-Host "Pausing for 30 seconds" -ForegroundColor Green
Start-Sleep 30
Write-Host "Adding ADF Identity to SQL Admins Group" -ForegroundColor Cyan
Add-AzADGroupMember -MemberObjectId $adfIdentityObjectId -TargetGroupObjectId $sqlAdminsObjectId -ErrorAction SilentlyContinue
Write-Host "Membership added. Beginning deployment." -ForegroundColor Cyan

Write-Host ""

$deploymentName = "$timeStamp-dataservices"

az configure --defaults group="$resourceGroupName"
az deployment group create `
    --name "$deploymentName" `
    --template-file '01-dataservices.bicep' `
    --parameters dataservices.params.json `
        orgPrefix=$orgPrefix `
        appPrefix=$appPrefix `
        regionCode=$regionCode `
        sqlAdminObjectId=$sqlAdminsObjectId `
        userAssignedIdentityName=$userAssignedIdentityName `
        servicePrincipalSecret=$servicePrincipalSecret `
        updateServicePrincipalSecret=$updateServicePrincipalSecret


$deploymentOutputs = (Get-AzResourceGroupDeployment -ResourceGroupName $resourceGroupName -Name $deploymentName).Outputs

$irName = $deploymentOutputs.integrationRuntimeName.value
Write-Host "Integration Runtime Name: $irName" -ForegroundColor Cyan

$akvName = $deploymentOutputs.keyVaultName.value
Write-Host "Key Vault Name: $akvName" -ForegroundColor Cyan

$akvSecretName = $deploymentOutputs.keyVaultSecretName.value
Write-Host "Key Vault Secret Name: $akvSecretName" -ForegroundColor Cyan

$dfCredentialName = $deploymentOutputs.dataFactoryCredentialName.value
Write-Host "Data Factory Credential Name: $dfCredentialName" -ForegroundColor Cyan

$sqlServerDnsName = $deploymentOutputs.sqlServerDnsName.value
Write-Host "SQL Server DNS Name: $sqlServerDnsName" -ForegroundColor Cyan

$databaseName = $deploymentOutputs.databaseName.value
Write-Host "Database Name: $databaseName" -ForegroundColor Cyan

$deploymentName = "$timeStamp-datafactory"

Write-Host "Pausing for 30 seconds" -ForegroundColor Green
Start-Sleep 30

az deployment group create `
    --name "$deploymentName" `
    --template-file '02-datafactory.bicep' `
    --parameters datafactory.params.json `
        integrationRuntimeName=$irName `
        keyVaultName=$akvName `
        keyVaultSecretName=$akvSecretName `
        dataFactoryCredentialName=$dfCredentialName `
        sqlServerDnsName=$sqlServerDnsName `
        databaseName=$databaseName `
        servicePrincipalAppId=$servicePrincipalAppId
