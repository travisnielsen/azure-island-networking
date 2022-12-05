$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]

az deployment sub create --name "$timeStamp-appbase" --location $location --template-file application-base.bicep --parameters application-base.params.json