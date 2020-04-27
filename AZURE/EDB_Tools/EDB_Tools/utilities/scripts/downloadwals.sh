#!/bin/bash

ACCESS_TOKEN=`curl 'http://169.254.169.254/metadata/identity/oauth2/token?api-version=2018-02-01&resource=https%3A%2F%2Fmanagement.azure.com%2F' -H Metadata:true|awk -F ':|,' '{print $2}' | tr '"' ' '`

STORAGE_ACCOUNT_KEY=`curl https://management.azure.com/subscriptions/SUBSCRIPTION_ID/resourceGroups/RESOURCE_GROUP/providers/Microsoft.Storage/storageAccounts/STORAGE_NAME/listKeys?api-version=2016-12-01 --request POST -d "" -H "Authorization: Bearer $ACCESS_TOKEN" | awk -F ':|,' '{print $5}' | tr '"' ' '`

az storage blob download -c CONTAINER_NAME -n $1 -f $2 --account-name STORAGE_NAME --account-key $STORAGE_ACCOUNT_KEY
