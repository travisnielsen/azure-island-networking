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

$keyData = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDDAoSQ08WhT+kemOjkKoQZKNieWiMZq0CtZs/+2T7E//T9sOfLkGLWcYD12qqTRb0wLiqKRlaaeOFOq9ShloF7eZRZUFrw8nvCA5w+O3N7WTt+lwJXPZKZDyUZeTaLcR++QgOD0k+Q0l6WTlXvA7oZwTV8ZroN99nuP75tXs+q9CFbAjkfbHXhiv35xw0bk79Ipe8aPfPutP24CW6XcOXpnI6+bCkfFRUAKvQ+YXgWC+8ZyXoi0TlgvxvsNk4hbrx1CMM3NRJHSpz2ve8WLsrWGexmbDEWhn0U7kG9xQnDMiql4suHuYOZklmTVOHCQMEG9iC/toe/zkqbUJbofOWrDD8GOvXgCtxMpzmTHHFg4WqZ2N+LJj/OiH7tU1O1zECH/cFXRs53cvF1U6RZbSdPKeTszTkzwuLjf+9I26Be1K5vy/kt7Ef77nH5cj7BOT0eerH52zlfXdcNxjK4roVl4+ooH17I6NA7eXLBGbk2xseCEFsRWsHNaMiUPL9erjpdd0M9gLnshEHSZOpJJJV2RZr0d5QlKr1+PJ9tsf9qZ5px6LhhgSeNAsJ9MKui0aqHxoxW/AxLrLnGamNxYp+L5w9eE1RWKtGGQHyNvf2qQciGt1ddSEY2z8fznzAckfflGOCMh4pn9BR/78v15pBD1TtRrrof1LXA3CBGkAtxcQ=="

az configure --defaults group="$orgPrefix-$appPrefix-workload"
az deployment group create --name "$timeStamp-appsvc" --template-file app-services.bicep --parameters orgPrefix=$orgPrefix appPrefix=$appPrefix regionCode=$regionCode keyData="$keyData"