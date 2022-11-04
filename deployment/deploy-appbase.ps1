#az group create --name privatepaas --location "centralus"
#az deployment group create -g privatepaas -f sample-function.json

$timeStamp = Get-Date -Format "yyyyMMddHHmm"
$location = $Args[0]

az deployment sub create --name "$timeStamp-appbase" --location $location --template-file application-base.bicep --parameters application-base.params.json region=$location