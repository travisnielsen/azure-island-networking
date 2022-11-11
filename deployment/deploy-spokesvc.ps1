$timeStamp = Get-Date -Format "yyyyMMddHHmm"
az group create --name contoso-spoke-services --location "centralus"
az deployment group create --name "$timeStamp-spokesvc" --resource-group contoso-spoke-services --template-file spoke-services.bicep --parameters spoke-services.params.json