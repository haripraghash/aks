#!/bin/bash
i=0
kubeletidentity=$(az aks show -n $1 -g $2 --query 'identityProfile.kubeletidentity.objectId' --output tsv) 
while [ -z "$kubeletidentity" ] 
do
    ((i++))
    kubeletidentity=$(az aks show -n $1 -g $2  --query 'identityProfile.kubeletidentity.objectId' --output tsv)
    if [ $i -eq 30 ] 
    then
        break
    fi
done

if [ ! -z "$kubeletidentity" ]
then
# Populate value required for subsequent command args
ACR_REGISTRY_ID=$(az acr show --name $3 --query id --output tsv)

# Assign the desired role to the service principal. Modify the '--role' argument
az role assignment create --assignee $kubeletidentity --scope $ACR_REGISTRY_ID --role acrpull
fi
