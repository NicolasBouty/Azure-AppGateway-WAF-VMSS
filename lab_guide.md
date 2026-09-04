
# 🚀 Step-by-Step Deployment Guide
---

# Phase 1 : Network Foundation Infrastructure
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

# ✅ Phase 1 — Verification & Proofs

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
Deny-All-Outbound                    4096        Outbound     Deny      *            *                        *
```
---

# Phase 3 — Fichiers cloud-init hors ligne

## 1. Contenu des fichiers

### cloud-init-web.yaml
```yaml
cat <<'EOF' > cloud-init-web.yaml
#cloud-config

write_files:
  - path: /etc/systemd/system/az104-web.service
    permissions: '0644'
    owner: root:root
    content: |
      [Unit]
      Description=AZ-104 Lab Web Backend
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/python3 -m http.server 80 --directory /srv/az104/web
      Restart=always
      RestartSec=3

      [Install]
      WantedBy=multi-user.target

runcmd:
  - mkdir -p /srv/az104/web
  - printf 'OK-WEB\n' > /srv/az104/web/index.html
  - chmod 0644 /srv/az104/web/index.html
  - systemctl daemon-reload
  - systemctl enable --now az104-web.service
```

### cloud-init-api.yaml
```yaml
cat <<'EOF' > cloud-init-api.yaml
#cloud-config

write_files:
  - path: /etc/systemd/system/az104-api.service
    permissions: '0644'
    owner: root:root
    content: |
      [Unit]
      Description=AZ-104 Lab API Backend
      After=network-online.target
      Wants=network-online.target

      [Service]
      Type=simple
      ExecStart=/usr/bin/python3 -m http.server 80 --directory /srv/az104/api
      Restart=always
      RestartSec=3

      [Install]
      WantedBy=multi-user.target

runcmd:
  - mkdir -p /srv/az104/api/api
  - printf 'OK-API-ROOT\n' > /srv/az104/api/index.html
  - printf 'OK-API\n' > /srv/az104/api/api/index.html
  - printf 'OK-API-HEALTHY\n' > /srv/az104/api/api/health
  - chmod 0644 /srv/az104/api/index.html /srv/az104/api/api/index.html /srv/az104/api/api/health
  - systemctl daemon-reload
  - systemctl enable --now az104-api.service
EOF
```
### vérification
```Bash
ls -l cloud-init-*.yaml
```
### résulta 
```Bash
resulta
```
---

## 2. Déploiement des VMSS
Les VM Scale Sets sont déployés en mode d’orchestration Uniform avec une politique d’upgrade Manual. 
Le mode Rolling n’est pas activé dans ce lab, car il nécessite une source de santé VMSS — Application Health Extension ou Azure Load Balancer Health Probe — qui n’est pas incluse afin de respecter la contrainte de zéro egress depuis les machines virtuelles. 
La sonde Application Gateway est utilisée uniquement pour la disponibilité des backends dans le routage applicatif
### a. Déploiement initial
```Bash
#!/usr/bin/env bash
set -euo pipefail

# Variables

RG_NETWORK="grp_tpaz104-lab"
RG_WORKLOAD="grp_tpaz104-lab2"
LOCATION="westeurope"
VNET_NAME="vnet_tpaz104-lab"

ADMIN_USER="azureuser"
SKU_VMSS="Standard_D2als_v7"
SKU_JUMPBOX=Standard_D2als_v7"
IMAGE_UBUNTU="Canonical:ubuntu-24_04-lts:server:latest"

CLOUD_INIT_WEB="cloud-init-web.yaml"
CLOUD_INIT_API="cloud-init-api.yaml"

# Contrôles préalables

for file in "$CLOUD_INIT_WEB" "$CLOUD_INIT_API"; do
  if [ ! -f "$file" ]; then
    echo "Erreur : fichier introuvable : $file"
    exit 1
  fi

  if ! head -n 1 "$file" | grep -qx '#cloud-config'; then
    echo "Erreur : $file doit commencer par : #cloud-config"
    exit 1
  fi
done

# Le même mot de passe est utilisé uniquement pour le lab :
# - console série de la Jumpbox
# - SSH interne optionnel vers les VMSS
read -rsp "Mot de passe local pour Jumpbox et VMSS : " ADMIN_PASSWORD
echo

if [ -z "$ADMIN_PASSWORD" ]; then
  echo "Erreur : le mot de passe ne peut pas être vide."
  exit 1
fi

# IDs des subnets — VNet dans le RG réseau

SUBNET_WEB_ID=$(az network vnet subnet show \
  --resource-group "$RG_NETWORK" \
  --vnet-name "$VNET_NAME" \
  --name subnet-backend-a \
  --query id \
  --output tsv)

SUBNET_API_ID=$(az network vnet subnet show \
  --resource-group "$RG_NETWORK" \
  --vnet-name "$VNET_NAME" \
  --name subnet-backend-b \
  --query id \
  --output tsv)

SUBNET_MGMT_ID=$(az network vnet subnet show \
  --resource-group "$RG_NETWORK" \
  --vnet-name "$VNET_NAME" \
  --name subnet-mgmt \
  --query id \
  --output tsv)

if [ -z "$SUBNET_WEB_ID" ] || [ -z "$SUBNET_API_ID" ] || [ -z "$SUBNET_MGMT_ID" ]; then
  echo "Erreur : impossible de récupérer au moins un ID de subnet."
  exit 1
fi

# VMSS Web

echo "=== Création du VMSS Web ==="

az vmss create \
  --resource-group "$RG_WORKLOAD" \
  --name vmss-web \
  --location "$LOCATION" \
  --orchestration-mode Uniform \
  --upgrade-policy-mode Manual \
  --image "$IMAGE_UBUNTU" \
  --vm-sku "$SKU_VMSS" \
  --instance-count 1 \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --authentication-type password \
  --subnet "$SUBNET_WEB_ID" \
  --custom-data "$CLOUD_INIT_WEB"

# VMSS API

echo "=== Création du VMSS API ==="

az vmss create \
  --resource-group "$RG_WORKLOAD" \
  --name vmss-api \
  --location "$LOCATION" \
  --orchestration-mode Uniform \
  --upgrade-policy-mode Manual \
  --image "$IMAGE_UBUNTU" \
  --vm-sku "$SKU_VMSS" \
  --instance-count 1 \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --authentication-type password \
  --subnet "$SUBNET_API_ID" \
  --custom-data "$CLOUD_INIT_API"

# Jumpbox

echo "=== Création de la Jumpbox privée ==="

az vm create \
  --resource-group "$RG_WORKLOAD" \
  --name vm-jumpbox \
  --location "$LOCATION" \
  --image "$IMAGE_UBUNTU" \
  --size "$SKU_JUMPBOX" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$ADMIN_PASSWORD" \
  --authentication-type password \
  --subnet "$SUBNET_MGMT_ID" \
  --public-ip-address "" \
  --boot-diagnostics true

# Réduit l'exposition du mot de passe dans l'environnement shell.
unset ADMIN_PASSWORD
echo "=== Déploiement des VMSS terminé. ==="

#Assurer l’absence d’IP publique VMSS
echo "=== Vérification : aucune IP publique sur les VMSS et la Jumpbox ==="

az network public-ip list \
  --query "[].{
    Name:name,
    ResourceGroup:resourceGroup,
    IP:ipAddress,
    AttachedTo:ipConfiguration.id
  }" \
  --output table
```

### b. Autoscale — min. 1 / max. 2 par VMSS
Le VMSS est configuré pour un scale-out à deux instances lorsque la moyenne CPU dépasse 70% pendant cinq minutes, et un scale-in lorsqu’elle passe sous 30% pendant dix minutes. 
Le lab ne génère pas artificiellement de charge : cette étape valide la configuration Azure Monitor Autoscale, pas le déclenchement effectif de la règle

```Bash
echo "=== Configuration Autoscale : VMSS Web (min=1, max=2) ==="

az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource vmss-web \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-vmss-web \
  --min-count 1 \
  --max-count 2 \
  --count 1

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name autoscale-vmss-web \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1 \
  --cooldown 5

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name autoscale-vmss-web \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1 \
  --cooldown 10

echo "=== Configuration Autoscale : VMSS API (min=1, max=2) ==="

az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource vmss-api \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-vmss-api \
  --min-count 1 \
  --max-count 2 \
  --count 1

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name autoscale-vmss-api \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1 \
  --cooldown 5

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name autoscale-vmss-api \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1 \
  --cooldown 10

echo "=== Autoscale configuré : min=1 / défaut=1 / max=2 pour VMSS WEB et API ==="
```

### Vérifications d'Autoscale
### VMSS WEB
```Bash
az monitor autoscale show \
  --resource-group "$RG_WORKLOAD" \
  --name autoscale-vmss-web \
  --output jsonc
```
### résulta 
```Bash
resulta
```
### VMSS API
```Bash
  az monitor autoscale show \
  --resource-group "$RG_WORKLOAD" \
  --name autoscale-vmss-api \
  --output jsonc
```
### résulta 
```Bash
resulta
```
### Vérifications des instance
```Bash
az vmss list-instances \
  --resource-group "$RG_WORKLOAD" \
  --name vmss-web \
  --query "[].{
    Instance:instanceId,
    Provisioning:provisioningState,
    Power:powerState
  }" \
  --output table
```
### résulta 
```Bash
resulta
```
---

# Phase 4


