#az group create --name privatepaas --location "centralus"
#az deployment group create -g privatepaas -f sample-function.json

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

az configure --defaults group="$orgPrefix-$appPrefix-workload"
az deployment group create --name "$timeStamp-appsvc" --template-file application-services.bicep --parameters application-services.params.json orgPrefix=$orgPrefix appPrefix=$appPrefix regionCode=$regionCode