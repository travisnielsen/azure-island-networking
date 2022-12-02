Function DecoratedOutput {
    param(
        [Parameter (Mandatory = $true)] [String]$baseMessage,
        [Parameter (Mandatory = $false)] [String]$secondaryMessage
    )

    Write-Host "$(Get-Date -Format G): " -ForegroundColor Yellow -NoNewline

    if ($secondaryMessage) {
        Write-Host "$baseMessage " -NoNewLine
        Write-Host "$secondaryMessage" -ForegroundColor Green
    }
    else {
        Write-Host "$baseMessage"
    }    
}

$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$orgPrefix = $Args[1]
$appPrefix = $Args[2]
$targetResourceGroup = "$orgPrefix-$appPrefix-workload"

DecoratedOutput "Deploying Core..."
$core_output = az deployment sub create --name "$timeStamp-core" --location $location --template-file core.bicep --parameters core.params.json
DecoratedOutput "Core Deployed."

DecoratedOutput "Deploying App Base..."
$appbase_output = az deployment sub create --name "$timeStamp-appbase" --location $location --template-file application-base.bicep --parameters application-base.params.json
DecoratedOutput "App Base Deployed."

DecoratedOutput "Setting Target Resource Group to" $targetResourceGroup
az configure --defaults group="$targetResourceGroup"

DecoratedOutput "Deploying App Services..."
$appsvc_output = az deployment group create --name "$timeStamp-appsvc" --template-file application-services.bicep --parameters application-services.params.json
DecoratedOutput "App Services Deployed."