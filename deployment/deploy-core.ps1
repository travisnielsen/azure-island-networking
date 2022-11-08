$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$appPrefix = $Args[1]

az deployment sub create --name "$timeStamp-core" --location $location --template-file core.bicep --parameters core.params.json region=$location appPrefix=$appPrefix