#!/bin/bash

# Variables
resourceGroup="cloud-demo"
location="westus"
osType="UbuntuLTS"
vmssName="udacity-vmss"
adminName="udacityadmin"
storageAccount="udacitydiag$RANDOM"
bePoolName="$vmssName-bepool"
lbName="$vmssName-lb"
lbRule="$lbName-network-rule"
nsgName="$vmssName-nsg"
vnetName="$vmssName-vnet"
subnetName="$vnetName-subnet"
probeName="tcpProbe"
vmSize="Standard_B1s"
storageType="Standard_LRS"

# Create resource group. 
# This command will not work for the Cloud Lab users. 
# Cloud Lab users can comment this command and 
# use the existing Resource group name, such as, resourceGroup="cloud-demo-153430" 
# Create Storage account
echo "STEP 1 - Creating storage account $storageAccount"

az storage account create --name $storageAccount --resource-group $resourceGroup --location $location --sku Standard_LRS

echo "Storage account created: $storageAccount"

# Create Network Security Group
echo "STEP 2 - Creating network security group $nsgName"

az network nsg create --resource-group $resourceGroup --name $nsgName --verbose
az network nsg create --resource-group cloud-demo --name vmssproject1-nsg --verbose
echo "Network security group created: $nsgName"

# Create VM Scale Set
echo "STEP 3 - Creating VM scale set $vmssName"

az vmss create --resource-group $resourceGroup --name $vmssName --image $osType --vm-sku $vmSize --nsg $nsgName --subnet $subnetName --vnet-name $vnetName --backend-pool-name $bePoolName --storage-sku $storageType --load-balancer $lbName --custom-data cloud-init.txt --upgrade-policy-mode automatic --admin-username $adminName --generate-ssh-keys --verbose 
az vmss create --resource-group cloud-demo --name vmssproject1 --image UbuntuLTS --vm-sku Standard_B1s --nsg vmssproject1-nsg --subnet cloud-demo-vnet --vnet-name vmssproject1-vnet --backend-pool-name vmssproject1-bepool --storage-sku Standard_LRS --load-balancer vmssproject1-lb --custom-data cloud-init.txt --upgrade-policy-mode automatic --admin-username saruadmin --generate-ssh-keys --verbose
echo "VM scale set created: $vmssName"

# Associate NSG with VMSS subnet
echo "STEP 4 - Associating NSG: $nsgName with subnet: $subnetName"

az network vnet subnet update --resource-group $resourceGroup --name $subnetName --vnet-name $vnetName --network-security-group $nsgName --verbose
az network vnet subnet update --resource-group cloud-demo --name cloud-demo-vnet --vnet-name vmssproject1-vnet --network-security-group vmssproject1-nsg --verbose
echo "NSG: $nsgName associated with subnet: $subnetName"

# Create Health Probe
echo "STEP 5 - Creating health probe $probeName"

az network lb probe create --resource-group $resourceGroup --lb-name $lbName --name $probeName --protocol tcp --port 80 --interval 5 --threshold 2 --verbose
az network lb probe create --resource-group cloud-demo --lb-name vmssproject1-lb --name tcpProbe --protocol tcp --port 80 --interval 5 --threshold 2 --verbose
echo "Health probe created: $probeName"

# Create Network Load Balancer Rule
echo "STEP 6 - Creating network load balancer rule $lbRule"

az network lb rule create --resource-group $resourceGroup --name $lbRule --lb-name $lbName --probe-name $probeName --backend-pool-name $bePoolName --backend-port 80 --frontend-ip-name loadBalancerFrontEnd --frontend-port 80 --protocol tcp --verbose
az network lb rule create --resource-group cloud-demo --name vmssproject1-lb-network-rule --lb-name vmssproject1-lb --probe-name tcpProbe --backend-pool-name vmssproject1-bepool --backend-port 80 --frontend-ip-name loadBalancerFrontEnd --frontend-port 80 --protocol tcp --verbose
echo "Network load balancer rule created: $lbRule"

# Add port 80 to inbound rule NSG
echo "STEP 7 - Adding port 80 to NSG $nsgName"

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Port_80 --destination-port-ranges 80 --direction Inbound --priority 100 --verbose
az network nsg rule create --resource-group cloud-demo --nsg-name vmssproject1-nsg --name Port_80 --destination-port-ranges 80 --direction Inbound --priority 100 --verbose
echo "Port 80 added to NSG: $nsgName"

# Add port 22 to inbound rule NSG
echo "STEP 8 - Adding port 22 to NSG $nsgName"

az network nsg rule create --resource-group $resourceGroup --nsg-name $nsgName --name Port_22 --destination-port-ranges 22 --direction Inbound --priority 110 --verbose
az network nsg rule create --resource-group cloud-demo --nsg-name vmssproject1-nsg --name Port_22 --destination-port-ranges 22 --direction Inbound --priority 100 --verbose
echo "Port 22 added to NSG: $nsgName"

echo "VMSS script completed!"
