
# 🚀 Step-by-Step Deployment Guide
---

# Phase 1: Network Foundation Infrastructure
## 1. Configuration Variables Setup

```Bash
LOCATION="westeurope"
RG_NAME="grp_tpaz104-lab"
VNET_NAME="vnet_tpaz104-lab"
PIP_NAME="pip-appgw"
```
---

## 2. Resource Group & VNet Creation

 Create Resource Group
```Bash
az group create \
  --name $RG_NAME \
  --location $LOCATION
```

 Create VNet and initial AppGW Subnet
```Bash
az network vnet create \
  --resource-group $RG_NAME \
  --name $VNET_NAME \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name subnet-appgw \
  --subnet-prefixes 10.0.1.0/24
```
---

## 3. Subnets Creation

 Web Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --address-prefixes 10.0.2.0/24
```

 API Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --address-prefixes 10.0.3.0/24
```

 Management Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --address-prefixes 10.0.4.0/24
```
---

## 4. Network Security Groups (NSG) Creation

```Bash
az network nsg create --resource-group $RG_NAME --name nsg-appgw --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-backend-a --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-backend-b --location $LOCATION
az network nsg create --resource-group $RG_NAME --name nsg-mgmt --location $LOCATION
```
---

## 5. NSG Subnet Association

```Bash
az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-appgw \
  --network-security-group nsg-appgw
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --network-security-group nsg-backend-a
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --network-security-group nsg-backend-b
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --network-security-group nsg-mgmt
```
---

## 6. Public IP Reservation

```Bash
az network public-ip create \
  --resource-group $RG_NAME \
  --name $PIP_NAME \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static
```
---

# ✅ Phase 1 Verification & Proofs

## Subnet & NSG Association Check
```Bash
az network vnet subnet list \
  --resource-group $RG_NAME \
  --vnet-name $VNET_NAME \
  --query "[].{Subnet:name, Prefix:addressPrefix, NSG:networkSecurityGroup.id}" \
  --output table
```

Output:
```bash
Subnet            Prefix       NSG
----------------  -----------  ------------------------------------------------------------------------------------------------------------------
subnet-appgw      10.0.1.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-appgw
subnet-backend-a  10.0.2.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-backend-a
subnet-backend-b  10.0.3.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-backend-b
subnet-mgmt       10.0.4.0/24  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-mgmt
```

## Public IP Provisioning Check
```Bash
az network public-ip show \
  --resource-group $RG_NAME \
  --name $PIP_NAME \
  --query "{Name:name, IP:ipAddress, SKU:sku.name, Allocation:publicIpAllocationMethod}" \
  --output table
```
Output:
```Bash
Name       IP            SKU
---------  ------------  --------
pip-appgw  20.160.25.38  Standard
```
---
## screenshot
resources :

<img width="851" height="293" alt="Capture d&#39;écran 2026-09-03 122619" src="https://github.com/user-attachments/assets/a20d8e13-7cbe-49ea-a1f4-69ffd81f6b11" />

---

# Phase 2 — Règles NSG

## 1. nsg-appgw
```Bash
APPGW_SUBNET="10.0.1.0/24"
RG_NAME="grp_tpaz104-lab"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Allow-Internet-Inbound \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix Internet \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_SUBNET" \
  --destination-port-ranges 80 443

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Allow-GatewayManager-Inbound \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix GatewayManager \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_SUBNET" \
  --destination-port-range 65200-65535

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Allow-AzureLoadBalancer-Inbound \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix AzureLoadBalancer \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_SUBNET" \
  --destination-port-range '*'

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## OUTBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Allow-VNet-Outbound \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix "$APPGW_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix VirtualNetwork \
  --destination-port-range '*'

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Allow-Internet-Outbound-Temp \
  --priority 110 \
  --direction Outbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix "$APPGW_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix Internet \
  --destination-port-range '*'

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --name Deny-All-Outbound \
  --priority 4096 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## vérifier le résultat avec
```Bash
az network nsg rule list \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-appgw \
  --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Source:sourceAddressPrefix, Dest:destinationAddressPrefix, DestPort:destinationPortRange}" \
  --output table
```
## résulta :
```Bash
Name                             Priority    Direction    Access    Source             Dest            DestPort
-------------------------------  ----------  -----------  --------  -----------------  --------------  -----------
Allow-Internet-Inbound           100         Inbound      Allow     Internet           10.0.1.0/24
Allow-GatewayManager-Inbound     110         Inbound      Allow     GatewayManager     10.0.1.0/24     65200-65535
Allow-AzureLoadBalancer-Inbound  120         Inbound      Allow     AzureLoadBalancer  10.0.1.0/24     *
Deny-All-Inbound                 4096        Inbound      Deny      *                  *               *
Allow-VNet-Outbound              100         Outbound     Allow     10.0.1.0/24        VirtualNetwork  *
Allow-Internet-Outbound-Temp     110         Outbound     Allow     10.0.1.0/24        Internet        *
Deny-All-Outbound                4096        Outbound     Deny      *                  *               *
```
---

## 2. nsg-backend-a
```Bash
APPGW_SUBNET="10.0.1.0/24"
WEB_SUBNET="10.0.2.0/24"
MGMT_SUBNET="10.0.4.0/24"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Allow-HTTP-From-AppGW \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$APPGW_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$WEB_SUBNET" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Allow-SSH-From-Jumpbox \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$WEB_SUBNET" \
  --destination-port-range 22

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Allow-HTTP-From-Jumpbox-LabTest \
  --priority 115 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$WEB_SUBNET" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Deny-Test-Port-8080 \
  --priority 200 \
  --direction Inbound \
  --access Deny \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$WEB_SUBNET" \
  --destination-port-range 8080

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## OUTBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --name Deny-All-Outbound \
  --priority 4096 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## vérifier le résultat avec
```Bash
az network nsg rule list \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-a \
  --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Source:sourceAddressPrefix, Dest:destinationAddressPrefix, DestPort:destinationPortRange}" \
  --output table
```
## résulta :
```Bash
Name                             Priority    Direction    Access    Source       Dest         DestPort
-------------------------------  ----------  -----------  --------  -----------  -----------  ----------
Allow-HTTP-From-AppGW            100         Inbound      Allow     10.0.1.0/24  10.0.2.0/24  80
Allow-SSH-From-Jumpbox           110         Inbound      Allow     10.0.4.0/24  10.0.2.0/24  22
Allow-HTTP-From-Jumpbox-LabTest  115         Inbound      Allow     10.0.4.0/24  10.0.2.0/24  80
Deny-Test-Port-8080              200         Inbound      Deny      10.0.4.0/24  10.0.2.0/24  8080
Deny-All-Inbound                 4096        Inbound      Deny      *            *            *
Deny-All-Outbound                4096        Outbound     Deny      *            *            *
```
---

## 3. nsg-backend-b
```Bash
APPGW_SUBNET="10.0.1.0/24"
API_SUBNET="10.0.3.0/24"
MGMT_SUBNET="10.0.4.0/24"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Allow-HTTP-From-AppGW \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$APPGW_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$API_SUBNET" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Allow-SSH-From-Jumpbox \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$API_SUBNET" \
  --destination-port-range 22

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Allow-HTTP-From-Jumpbox-LabTest \
  --priority 115 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$API_SUBNET" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Deny-Test-Port-8080 \
  --priority 200 \
  --direction Inbound \
  --access Deny \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$API_SUBNET" \
  --destination-port-range 8080

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## OUTBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --name Deny-All-Outbound \
  --priority 4096 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## vérifier le résultat avec
```Bash
az network nsg rule list \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-backend-b \
  --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Source:sourceAddressPrefix, Dest:destinationAddressPrefix, DestPort:destinationPortRange}" \
  --output table
```
## résulta :
```Bash
Name                             Priority    Direction    Access    Source       Dest         DestPort
-------------------------------  ----------  -----------  --------  -----------  -----------  ----------
Allow-HTTP-From-AppGW            100         Inbound      Allow     10.0.1.0/24  10.0.3.0/24  80
Allow-SSH-From-Jumpbox           110         Inbound      Allow     10.0.4.0/24  10.0.3.0/24  22
Allow-HTTP-From-Jumpbox-LabTest  115         Inbound      Allow     10.0.4.0/24  10.0.3.0/24  80
Deny-Test-Port-8080              200         Inbound      Deny      10.0.4.0/24  10.0.3.0/24  8080
Deny-All-Inbound                 4096        Inbound      Deny      *            *            *
Deny-All-Outbound                4096        Outbound     Deny      *            *            *
```
---

## 4. nsg-mgmt
```Bash
MGMT_SUBNET="10.0.4.0/24"
WEB_SUBNET="10.0.2.0/24"
API_SUBNET="10.0.3.0/24"
APPGW_PRIVATE_IP="10.0.1.10"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --name Deny-All-Inbound \
  --priority 4096 \
  --direction Inbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## OUTBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --name Allow-SSH-To-Backends \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefixes "$WEB_SUBNET" "$API_SUBNET" \
  --destination-port-range 22

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --name Allow-HTTP-To-AppGW-PrivateFrontend \
  --priority 110 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_PRIVATE_IP" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --name Allow-HTTP-To-Backends-LabTest \
  --priority 120 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefixes "$WEB_SUBNET" "$API_SUBNET" \
  --destination-port-range 80

az network nsg rule create \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --name Deny-All-Outbound \
  --priority 4096 \
  --direction Outbound \
  --access Deny \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```
## vérifier le résultat avec
```Bash
az network nsg rule list \
  --resource-group "$RG_NAME" \
  --nsg-name nsg-mgmt \
  --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Source:sourceAddressPrefix || join(',', sourceAddressPrefixes), Dest:destinationAddressPrefix || join(',', destinationAddressPrefixes), DestPort:destinationPortRange}" \
  --output table
```
## résulta :
```Bash
Name                                 Priority    Direction    Access    Source       Dest                     DestPort
-----------------------------------  ----------  -----------  --------  -----------  -----------------------  ----------
Deny-All-Inbound                     4096        Inbound      Deny      *            *                        *
Allow-SSH-To-Backends                100         Outbound     Allow     10.0.4.0/24  10.0.2.0/24,10.0.3.0/24  22
Allow-HTTP-To-AppGW-PrivateFrontend  110         Outbound     Allow     10.0.4.0/24  10.0.1.10                80
Allow-HTTP-To-Backends-LabTest       120         Outbound     Allow     10.0.4.0/24  10.0.2.0/24,10.0.3.0/24  80
Deny-All-Outbound                    4096        Outbound     Deny      *            *                        *
```
---


