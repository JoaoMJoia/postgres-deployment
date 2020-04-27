#!/bin/bash

MasterPublicIP=eip

Master_IP=$2

Slave_IP=$1

# Find IPconfig name of failed master

ipconfigname=$(az network nic list --resource-group RGNAME --query "[?ipConfigurations[?privateIpAddress=='$Master_IP']]"|grep name | grep -v null |awk -F : '{print $2}'| tr '",' ' '|sed -n 1p)

# Find NIC name of failed master

nic_name=$(az network nic list --resource-group RGNAME --query "[?ipConfigurations[?privateIpAddress=='$Master_IP']]"|grep name | grep -v null |awk -F : '{print $2}'| tr '",' ' '|sed -n 2p)

# Disassociate the Public IP of the failed Master Server

az network nic ip-config update --name $ipconfigname --nic-name $nic_name --resource-group RGNAME --remove PublicIpAddress



# Find IPconfig name of New Master

ipconfigname_slave=$(az network nic list --resource-group RGNAME --query "[?ipConfigurations[?privateIpAddress=='$Slave_IP']]"|grep name | grep -v null |awk -F : '{print $2}'| tr '",' ' '|sed -n 1p)

# Find NIC name of New master

nic_name_slave=$(az network nic list --resource-group testing-cds --query "[?ipConfigurations[?privateIpAddress=='$Slave_IP']]"|grep name | grep -v null |awk -F : '{print $2}'| tr '",' ' '|sed -n 2p)


# Associate Public IP address to new Master

az network nic ip-config update -g RGNAME --nic-name $nic_name_slave -n $ipconfigname_slave --public-ip-address MasterPublicIP


