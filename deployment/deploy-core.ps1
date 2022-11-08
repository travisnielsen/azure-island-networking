$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]
$orgPrefix = $Args[1]

az deployment sub create --name "$timeStamp-core" --location $location --template-file core.bicep --parameters core.params.json region=$location orgPrefix=$orgPrefix