
🚀 Step-by-Step Deployment Guide
---
Phase 1: Network Foundation Infrastructure
1. Configuration Variables Setup

```Bash
LOCATION="westeurope"
RG_NAME="grp_tpaz104-lab"
VNET_NAME="vnet_tpaz104-lab"
PIP_NAME="pip-appgw"
```
---
2. Resource Group & VNet Creation

# Create Resource Group
```Bash
az group create \
  --name $RG_NAME \
  --location $LOCATION
```

# Create VNet and initial AppGW Subnet
```Bash
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name subnet-appgw \
  --subnet-prefixes 10.0.1.0/24
```
---
3. Subnets Creation
Bash

# Web Subnet
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --address-prefixes 10.0.2.0/24

# API Subnet
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --address-prefixes 10.0.3.0/24

# Management Subnet
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --address-prefixes 10.0.4.0/24

4. Network Security Groups (NSG) Creation
Bash

az network nsg create --resource-group $RG_NAME --name nsg-appgw --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-backend-a --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-backend-b --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-mgmt --location $LOCATION

5. NSG Subnet Association
Bash

az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-appgw \
  --network-security-group nsg-appgw

az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --network-security-group nsg-backend-a

az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --network-security-group nsg-backend-b

az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --network-security-group nsg-mgmt

6. Public IP Reservation
Bash

az network public-ip create \
  --resource-group $RG_NAME \
  --name $PIP_NAME \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static

✅ Phase 1 Verification & Proofs
Subnet & NSG Association Check
Bash

az network vnet subnet list \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --query "[].{Subnet:name, Prefix:addressPrefix, NSG:networkSecurityGroup.id}" \
  --output table

Output:
Plaintext

Subnet            Prefix       NSG
----------------  -----------  ------------------------------------------------------------------------------------------------------------------
subnet-appgw      10.0.1.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-appgw
subnet-backend-a  10.0.2.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-backend-a
subnet-backend-b  10.0.3.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-backend-b
subnet-mgmt       10.0.4.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-mgmt

Public IP Provisioning Check
Bash

az network public-ip show \
  --resource-group $RG_NAME \
  --name $PIP_NAME \
  --query "{Name:name, IP:ipAddress, SKU:sku.name, Allocation:publicIpAllocationMethod}" \
  --output table

Output:
Plaintext

Name       IP            SKU
---------  ------------  --------
pip-appgw  20.160.25.38  Standard
