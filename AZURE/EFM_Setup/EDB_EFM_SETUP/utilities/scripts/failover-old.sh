#!/bin/bash

#for master
MasterPublicIP=eip

Master_IP=$2

Slave_IP=$1

ipconfigname=$(az network nic list --resource-group testing-cds --query "[?ipConfigurations[?privateIpAddress=='$Master_IP']]"|grep name | grep -v null |awk -F : '{print $2}'| tr '",' ' '|sed -n 1p


vm_name=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute.name')

nic_name=$(az vm nic list --vm-name $vm_name --resource-group RGNAME| grep id | awk -F ':|/' '{print $10}'|tr '",' ' ')

ipconfigname=$(az network nic ip-config list --nic-name $nic_name --resource-group RGNAME --out table|awk '{print $1}' | grep -v 'Name'|sed -n 2p)

az network nic ip-config update --name $ipconfigname --nic-name $nic_name --resource-group RGNAME --remove PublicIpAddress

elif [ "$IP" == "$Slave_IP"]

then

vm_name_slave=$(curl -s -H Metadata:true "http://169.254.169.254/metadata/instance?api-version=2017-08-01" | jq -r '.compute.name')

nic_name_slave=$(az vm nic list --vm-name $vm_name_slave --resource-group RGNAME| grep id | awk -F ':|/' '{print $10}'|tr '",' ' ')

ipconfigname_slave=$(az network nic ip-config list --nic-name $nic_name_slave --resource-group RGNAME --out table|awk '{print $1}' | grep -v 'Name'|sed -n 2p)

az network nic ip-config update -g RGNAME --nic-name $nic_name_slave -n $ipconfigname_slave --public-ip-address $MasterPublicIP

else

echo "Nothing to do"

fi



