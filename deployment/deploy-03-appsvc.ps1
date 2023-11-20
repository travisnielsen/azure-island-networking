$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$orgPrefix = $Args[1]
$appPrefix = $Args[2]
$keyData = $Args[3]

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


# $securityRgName = "$orgPrefix-$appPrefix-workload-security"
# az group create --name $securityRgName --location $location
# $sshKeyGenResult=az sshkey create --name "aks-ssh-key" --resource-group $securityRgName | ConvertFrom-Json -AsHashtable

# Write-Host "Created SSH key pair for AKS. Public Key is"
# $sshKeyGenResult.publicKey

az configure --defaults group="$orgPrefix-$appPrefix-workload"
az deployment group create --name "$timeStamp-appsvc" --template-file app-services.bicep --parameters '{ \"tags\": { \"value\": { \"project\": \"AzIslandNetworking\", \"component\": \"workload\" } } }'  orgPrefix=$orgPrefix appPrefix=$appPrefix regionCode=$regionCode keyData=$keyData