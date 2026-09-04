
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
## résultat :
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
## résultat :
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
## résultat :
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
## résultat :
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
## 📄 Rôle des fichiers Cloud-Init (`cloud-init-web.yaml` & `cloud-init-api.yaml`)

Ces fichiers permettent d'automatiser le **bootstrap hors ligne** (*zero-egress*) des instances lors du déploiement des **Virtual Machine Scale Sets (VMSS)**. 

Comme les sous-réseaux backend n'ont aucun accès à Internet (pas de NAT Gateway ni d'IP publique), ces scripts s'appuient uniquement sur les dépendances préinstallées dans l'image **Ubuntu Server 24.04 LTS** (comme `python3` et `systemd`) sans exécuter de commande `apt update` ou `apt install`.

### 🟢 `cloud-init-web.yaml` — Backend Web
* **Création de la structure :** Génère le répertoire `/srv/az104/web` et y injecte une page `index.html` contenant la chaîne de caractères `OK-WEB`.
* **Service Systemd (`az104-web.service`) :** Configure et active un serveur HTTP minimaliste via le module natif Python (`python3 -m http.server 80`).
* **Comportement :** Écoute sur le port 80 et sert la page racine `/` pour répondre aux sondes de santé et aux requêtes d'Aag.

### 🔵 `cloud-init-api.yaml` — Backend API
* **Structure d'arborescence :** Génère les répertoires et fichiers nécessaires pour simuler une API routée par chemin (*path-based routing*) :
  * `/srv/az104/api/index.html` $\rightarrow$ Renvoie `OK-API-ROOT`
  * `/srv/az104/api/api/index.html` $\rightarrow$ Renvoie `OK-API` (réponse sur la route `/api/`)
  * `/srv/az104/api/api/health` $\rightarrow$ Renvoie `OK-API-HEALTHY` (utilisé par la sonde de santé personnalisée de l'Application Gateway)
* **Service Systemd (`az104-api.service`) :** Démarre le serveur HTTP Python sur le port 80 ciblant le dossier `/srv/az104/api`.

### ⚙️ Fonctionnement du service Systemd
Les deux configurations injectent un service Systemd garantissant la haute disponibilité locale de l'application :
* **Départ automatique :** Le service démarre dès que le réseau est prêt (`After=network-online.target`).
* **Autoréparation :** Option `Restart=always` avec un délai de 3 secondes (`RestartSec=3`) pour relancer le serveur web automatiquement en cas de crash.
---

## 1. Contenu des fichiers

### cloud-init-web.yaml
```bash
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
EOF
```

### cloud-init-api.yaml
```bash
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
### résultat 
```Bash
nicolas [ ~ ]$ ls -l cloud-init-*.yaml
-rw-r--r-- 1 nicolas nicolas 839 Sep  4 11:21 cloud-init-api.yaml
-rw-r--r-- 1 nicolas nicolas 662 Sep  4 11:21 cloud-init-web.yaml
```
---

# Phase 4. Créer et exporter le certificat 

Le certificat appgw.pfx est généré localement pour le lab et n’est pas versionné, car il contient une clé privée. 
Il est importé manuellement dans Azure Cloud Shell au moment du déploiement

## 1. Créé le certificat
```Powershell
$PfxPassword = Read-Host `
  -AsSecureString `
  "Mot de passe à définir pour appgw.pfx"

$Cert = New-SelfSignedCertificate `
  -Subject "CN=appgw-lab.local" `
  -DnsName "appgw-lab.local" `
  -CertStoreLocation "Cert:\CurrentUser\My" `
  -FriendlyName "AZ-104 Lab Application Gateway" `
  -Type SSLServerAuthentication `
  -KeyExportPolicy Exportable `
  -KeyLength 2048 `
  -KeyAlgorithm RSA `
  -HashAlgorithm SHA256 `
  -Provider "Microsoft Software Key Storage Provider" `
  -NotAfter (Get-Date).AddYears(1)

if ($null -eq $Cert -or -not $Cert.HasPrivateKey) {
    throw "Échec de création du certificat avec clé privée."
}

$PfxPath = Join-Path $HOME "Downloads\appgw.pfx"

Export-PfxCertificate `
  -Cert $Cert `
  -FilePath $PfxPath `
  -Password $PfxPassword

Get-Item $PfxPath |
  Select-Object Name, FullName, Length, LastWriteTime
```

## 2. transférer le PFX vers Cloud Shell
Pour permettre aux scripts d'automatisation d'accéder au certificat lors de la configuration d'Azure Application Gateway, le fichier PFX généré localement doit être transféré vers l'environnement Cloud Shell :

1. Accédez à **Azure Cloud Shell** depuis le portail Azure.
2. Dans la barre d'outils supérieure de la console, cliquez sur l'icône **Upload/Download files** (icône représentant des flèches vers le haut et le bas).
3. Sélectionnez **Upload**.
4. Naviguez dans votre système local et sélectionnez le fichier :
   `<CHEMIN_VERS_FICHIER>\appgw.pfx`

### vérification
```Bash
ls -lh ~/appgw.pfx
```
### résultat 
```Bash
-rw-r--r-- 1 nicolas nicolas 2.7K Sep  4 12:59 /home/nicolas/appgw.pfx
```

## 3. Protéger le fichier dans Cloud Shell
```Bash
chmod 600 ~/appgw.pfx
```
### vérification
```Bash
ls -l ~/appgw.pfx
```
### résultat 
```Bash
-rw------- 1 nicolas nicolas 2722 Sep  4 12:59 /home/nicolas/appgw.pfx
```
---

# Phase 5. Déploiement de l'Appliquation-Gateway

## 1. Déploiement initial

10.0.2.4 est un backend temporaire de bootstrap.
Il ne représente pas une instance VMSS permanente.
Il sera remplacé par pool-web et pool-api.

```Bash
cat <<'EOF' > deploy-appgw-base.sh
#!/usr/bin/env bash
set -euo pipefail

# Variables

RG_NETWORK="grp_tpaz104-lab"
RG_WORKLOAD="grp_tpaz104-lab2"
LOCATION="westeurope"
VNET_NAME="vnet_tpaz104-lab"

APPGW_NAME="appgw-lab"
PUBLIC_IP_NAME="pip-appgw"
WAF_POLICY_NAME="waf-policy-lab"

APPGW_SUBNET_NAME="subnet-appgw"

# Backend temporaire obligatoire pour créer le squelette App Gateway.
# Il sera supprimé / remplacé après l'association des VMSS aux pools dédiés.
PLACEHOLDER_BACKEND="10.0.2.4"

# Certificat PFX déjà uploadé dans Cloud Shell.
PFX_FILE="$HOME/appgw.pfx"

# Vérifications préalables

echo "=== Vérification des prérequis ==="

az group show \
  --name "$RG_NETWORK" \
  --output none

az group show \
  --name "$RG_WORKLOAD" \
  --output none

if [ ! -f "$PFX_FILE" ]; then
  echo "Erreur : certificat PFX introuvable : $PFX_FILE"
  exit 1
fi

if [ ! -s "$PFX_FILE" ]; then
  echo "Erreur : certificat PFX vide : $PFX_FILE"
  exit 1
fi

SUBNET_APPGW_ID=$(az network vnet subnet show \
  --resource-group "$RG_NETWORK" \
  --vnet-name "$VNET_NAME" \
  --name "$APPGW_SUBNET_NAME" \
  --query id \
  --output tsv)

if [ -z "$SUBNET_APPGW_ID" ]; then
  echo "Erreur : impossible de récupérer l'ID du subnet Application Gateway."
  exit 1
fi

echo "Subnet App Gateway : $SUBNET_APPGW_ID"

PUBLIC_IP_INFO=$(az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PUBLIC_IP_NAME" \
  --query "{Name:name,Location:location,SKU:sku.name,Allocation:publicIPAllocationMethod,Assigned:ipConfiguration.id}" \
  --output json)

echo "Public IP : $PUBLIC_IP_INFO"

PIP_SKU=$(az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PUBLIC_IP_NAME" \
  --query sku.name \
  --output tsv)

PIP_ALLOCATION=$(az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PUBLIC_IP_NAME" \
  --query publicIPAllocationMethod \
  --output tsv)

if [ "$PIP_SKU" != "Standard" ] || [ "$PIP_ALLOCATION" != "Static" ]; then
  echo "Erreur : pip-appgw doit être SKU Standard et allocation Static."
  exit 1
fi

# Saisie du mot de passe PFX

read -rsp "Mot de passe du certificat appgw.pfx : " PFX_PASSWORD
echo

if [ -z "$PFX_PASSWORD" ]; then
  echo "Erreur : le mot de passe PFX ne peut pas être vide."
  exit 1
fi

# Création de la WAF Policy

echo "=== Création de la WAF Policy OWASP 3.2 ==="

az network application-gateway waf-policy create \
  --resource-group "$RG_WORKLOAD" \
  --name "$WAF_POLICY_NAME" \
  --location "$LOCATION" \
  --type OWASP \
  --version 3.2

# Création Application Gateway WAF v2

echo "=== Création de l'Application Gateway WAF v2 ==="
echo "Cette étape peut prendre plusieurs minutes."

az network application-gateway create \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --location "$LOCATION" \
  --sku WAF_v2 \
  --capacity 2 \
  --subnet "$SUBNET_APPGW_ID" \
  --public-ip-address "$PUBLIC_IP_NAME" \
  --frontend-port 443 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --cert-file "$PFX_FILE" \
  --cert-password "$PFX_PASSWORD" \
  --waf-policy "$WAF_POLICY_NAME" \
  --priority 100 \
  --servers "$PLACEHOLDER_BACKEND"

unset PFX_PASSWORD

# Création des pools backend métier

echo "=== Création du pool backend Web ==="

az network application-gateway address-pool create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name pool-web

echo "=== Création du pool backend API ==="

az network application-gateway address-pool create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name pool-api

# Vérifications

echo "=== Vérification de l'Application Gateway ==="

az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    Name:name,
    Location:location,
    State:provisioningState,
    SKU:sku.name,
    Capacity:sku.capacity,
    FrontendIPs:frontendIpConfigurations[].{
      Name:name,
      PublicIP:publicIPAddress.id,
      PrivateIP:privateIPAddress
    },
    FrontendPorts:frontendPorts[].{
      Name:name,
      Port:properties.port
    },
    BackendPools:backendAddressPools[].name,
    Listeners:httpListeners[].name,
    Rules:requestRoutingRules[].{
      Name:name,
      Type:ruleType,
      Priority:priority
    }
  }" \
  --output jsonc

echo "=== Vérification des pools backend ==="

az network application-gateway address-pool list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Backends:backendAddresses
  }" \
  --output table

echo "=== Socle Application Gateway créé avec succès. ==="
EOF

chmod +x deploy-appgw-base.sh
```

## 2. lancer le script
```Bash
./deploy-appgw-base.sh
```
### résultat
```Bash
résultat
```

## 3. Policy basculée en Prevention
```Bash
az network application-gateway waf-policy policy-setting update \
  --resource-group "$RG_WORKLOAD" \
  --policy-name waf-policy-lab \
  --mode Prevention
```

## 4. Ajouter le frontend privé
```Bash
az network application-gateway frontend-ip create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name private-frontend-ip \
  --private-ip-address 10.0.1.10
```
### vérification
```Bash
az network application-gateway frontend-ip list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --output table
```
### résultat
```Bash
résultat
```

## 4. Créer les probes
```Bash
# Probe Web
az network application-gateway probe create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name probe-web \
  --protocol Http \
  --host 127.0.0.1 \
  --path / \
  --port 80 \
  --interval 30 \
  --timeout 30 \
  --threshold 3 \
  --match-status-codes 200-399

# Probe API :
az network application-gateway probe create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name probe-api \
  --protocol Http \
  --host 127.0.0.1 \
  --path /api/health \
  --port 80 \
  --interval 30 \
  --timeout 30 \
  --threshold 3 \
  --match-status-codes 200-399
```

## 5. Créer les HTTP settings
```Bash
az network application-gateway http-settings create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name http-setting-web \
  --port 80 \
  --protocol Http \
  --timeout 30 \
  --probe probe-web

az network application-gateway http-settings create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name http-setting-api \
  --port 80 \
  --protocol Http \
  --timeout 30 \
  --probe probe-api
```

## 6. Créer le port frontend HTTP
```Bash
az network application-gateway frontend-port create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name port-80 \
  --port 80
```
Le port 443 a normalement déjà été créé par la commande initiale ; vérifie son nom avec :
```Bash
az network application-gateway frontend-port list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --output table
```
### résultat
```Bash
résultat
```

## 7. Créer le listener privé
```Bash
az network application-gateway http-listener create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name appgw-lab \
  --name private-http-listener \
  --frontend-port port-80 \
  --frontend-ip private-frontend-ip
```

## 8. Créer les URL path maps
La map publique :
```text
map-public
  /*       → pool-web + http-setting-web
  /api/*   → pool-api + http-setting-api
```

La map privée :
```text
map-private
  /*       → pool-web + http-setting-web
  /api/*   → pool-api + http-setting-api
```



---

# Phase 6. Déploiement des VMSS
Les VM Scale Sets sont déployés en mode d’orchestration Uniform avec une politique d’upgrade Manual. 
Le mode Rolling n’est pas activé dans ce lab, car il nécessite une source de santé VMSS — Application Health Extension ou Azure Load Balancer Health Probe — qui n’est pas incluse afin de respecter la contrainte de zéro egress depuis les machines virtuelles. 
La sonde Application Gateway est utilisée uniquement pour la disponibilité des backends dans le routage applicatif

---
## 1. Déploiement initial
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
SKU_JUMPBOX="Standard_D2als_v7"
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

### résultat
```Bash
Name                IP
------------------  -------------
pip-appgw           51.124.223.4
vmss-apiLBPublicIP  20.107.14.118
vmss-webLBPublicIP  20.229.53.63
nicolas [ ~ ]$ 
```

---
## 2. Autoscale — min. 1 / max. 2 par VMSS
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
### résultat 
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
### résultat 
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
### résultat 
```Bash
resulta
```
---

# Phase 6


