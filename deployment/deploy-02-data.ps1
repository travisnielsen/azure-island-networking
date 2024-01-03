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

# get objectid of the sqladmins group
# TODO: must ensure account is member of the tenant - there appear to be some complexities when executing this command from a guest account

# $sqlAdminGroup = Get-AzADGroup -DisplayName "sqladmins"
# $objectId = $sqlAdminGroup.Id
# Write-Host "objectId: $objectId"

az configure --defaults group="$resourceGroupName"
az deployment group create --name "$timeStamp-data" --template-file 'data-fabric.bicep' --parameters data.fabric.params.json orgPrefix=$orgPrefix appPrefix=$appPrefix regionCode=$regionCode
