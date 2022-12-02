$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]

az deployment sub create --name "$timeStamp-core" --location $location --template-file core.bicep --parameters core.params.json