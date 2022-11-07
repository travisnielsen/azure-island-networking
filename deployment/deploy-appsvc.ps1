#az group create --name privatepaas --location "centralus"
#az deployment group create -g privatepaas -f sample-function.json

$timeStamp = Get-Date -Format "yyyyMMddHHmm"

az configure --defaults group='contoso-workloadA-rg'
az deployment group create --name "$timeStamp-appsvc" --template-file application-services.bicep --parameters application-services.params.json