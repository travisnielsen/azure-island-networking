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
$servicePrincipalObjectId = ''
$servicePrincipalSecret = ''
$updateServicePrincipalSecret = $false

if ($sp) {
    Write-Host "Service Principal found. Using existing Service Principal" -ForegroundColor Yellow
    $servicePrincipalObjectId = $sp.AppId
    Write-Host "Service Principal Object ID: $servicePrincipalObjectId" -ForegroundColor Cyan
} else {
    Write-Host "Creating Service Principal: $servicePrincipalName. This will be used by Data Factory for accessing the Fabric Lakehouse" -ForegroundColor Cyan
    $sp = New-AzADServicePrincipal -DisplayName $servicePrincipalName
    $servicePrincipalObjectId = $sp.AppId
    $servicePrincipalSecret = $sp.PasswordCredentials.SecretText
    $updateServicePrincipalSecret = $true
    Write-Host "Service Principal Object ID: $servicePrincipalObjectId" -ForegroundColor Cyan
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
Write-Host "Pausing for 30 seconds" -ForegroundColor Cyan
Start-Sleep 30
Write-Host "Adding ADF Identity to SQL Admins Group" -ForegroundColor Cyan
Add-AzADGroupMember -MemberObjectId $adfIdentityObjectId -TargetGroupObjectId $sqlAdminsObjectId -ErrorAction SilentlyContinue
Write-Host "Membership added. Beginning deployment." -ForegroundColor Cyan

Write-Host ""

az configure --defaults group="$resourceGroupName"
az deployment group create `
    --name "$timeStamp-data" `
    --template-file 'dataservices.bicep' `
    --parameters dataservices.params.json `
        orgPrefix=$orgPrefix `
        appPrefix=$appPrefix `
        regionCode=$regionCode `
        sqlAdminObjectId=$sqlAdminsObjectId `
        userAssignedIdentityName=$userAssignedIdentityName `
        servicePrincipalAppId=$servicePrincipalAppId `
        servicePrincipalSecret=$servicePrincipalSecret `
        updateServicePrincipalSecret=$updateServicePrincipalSecret `
        --verbose
