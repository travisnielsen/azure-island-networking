az group create --name privatepaas --location "centralus"
az deployment group create -g privatepaas -f sample-function.json