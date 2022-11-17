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

az configure --defaults group="$orgPrefix-$appPrefix"
az deployment group create --name "$timeStamp-security" --template-file security.bicep --parameters orgPrefix=$orgPrefix appPrefix=$appPrefix region=$location regionCode=$regionCode