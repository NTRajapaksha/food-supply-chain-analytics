#!/bin/bash
set -e  # Exit immediately if a command fails

# --- Configuration Variables ---
UNIQUE_ID="001" 
RESOURCE_GROUP="rg-food-supply-chain-prod-$UNIQUE_ID"
LOCATION="centralindia"

# Resource Names
# Appending timestamp to ensure global uniqueness for storage
TIMESTAMP=$(date +%s)
STORAGE_ACCOUNT="stfoodchain$UNIQUE_ID$TIMESTAMP"
VM_NAME="vm-airflow-orchestrator"
ADMIN_USER="azureuser"

# VM Specs (ARM64 Optimized for Central India Availability)
# Using Standard_B2ps_v2 as B-series v1/v2 x64 are often restricted in this region for students
VM_SIZE="Standard_B2ps_v2" 
VM_IMAGE="Canonical:0001-com-ubuntu-server-jammy:22_04-lts-arm64:latest"

echo "================================================================"
echo "STARTING DEPLOYMENT: Food Supply Chain Analytics Infrastructure"
echo "Region: $LOCATION | VM Size: $VM_SIZE"
echo "================================================================"

# 1. Create Resource Group
echo ">>> [1/5] Creating Resource Group: $RESOURCE_GROUP..."
az group create --name $RESOURCE_GROUP --location $LOCATION

# 2. Create Storage Account
echo ">>> [2/5] Creating Storage Account: $STORAGE_ACCOUNT..."
az storage account create \
    --name $STORAGE_ACCOUNT \
    --resource-group $RESOURCE_GROUP \
    --location $LOCATION \
    --sku Standard_LRS \
    --kind StorageV2

# 3. Create Data Lake Containers
echo ">>> [3/5] Creating Blob Containers..."
# Retrieve Key for container creation
STORAGE_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP --account-name $STORAGE_ACCOUNT --query "[0].value" --output tsv)

# Creating containers with standard naming for Medallion Architecture
# These names match the Snowflake/dbt scripts in Phase 2/3
az storage container create --name "bronze" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
az storage container create --name "silver" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
az storage container create --name "gold" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
az storage container create --name "datasets" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
az storage container create --name "scripts" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY
az storage container create --name "logs" --account-name $STORAGE_ACCOUNT --account-key $STORAGE_KEY

# 4. Create Virtual Machine
echo ">>> [4/5] Creating Virtual Machine (ARM64 / Zone 1)..."
# Using Zone 1 and Standard Security to ensure allocation success
az vm create \
    --resource-group $RESOURCE_GROUP \
    --name $VM_NAME \
    --image $VM_IMAGE \
    --size $VM_SIZE \
    --admin-username $ADMIN_USER \
    --generate-ssh-keys \
    --public-ip-sku Standard \
    --security-type Standard \
    --zone 1

# 5. Configure Network Security Group (Open Ports)
echo ">>> [5/5] Opening Ports for Airflow (8080), Kafka (9092), Superset (8088)..."
az vm open-port --resource-group $RESOURCE_GROUP --name $VM_NAME --port 8080 --priority 1001
az vm open-port --resource-group $RESOURCE_GROUP --name $VM_NAME --port 9092 --priority 1002
az vm open-port --resource-group $RESOURCE_GROUP --name $VM_NAME --port 8088 --priority 1003

# --- Final Output ---
VM_IP=$(az vm show -d -g $RESOURCE_GROUP -n $VM_NAME --query publicIps -o tsv)

echo "================================================================"
echo "DEPLOYMENT COMPLETE!"
echo "----------------------------------------------------------------"
echo " Resource Group   : $RESOURCE_GROUP"
echo " Storage Account  : $STORAGE_ACCOUNT"
echo " VM IP Address    : $VM_IP"
echo " SSH Command      : ssh $ADMIN_USER@$VM_IP"
echo "================================================================"