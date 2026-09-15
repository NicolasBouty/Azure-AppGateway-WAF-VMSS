
#  Guide de déploiement étape par étape
---

# Phase 1. Infrastructure de base du réseau
## 1. Configuration des variables de configuration

```Bash
LOCATION="westeurope"
RG_NETWORK="grp_tpaz104-lab"
RG_WORKLOAD="grp_tpaz104-lab2"
VNET_NAME="vnet_tpaz104-lab"
PIP_NAME="pip-appgw"
```

## 2. Création des groupes de ressources et du VNet
### Créer les groupes de ressources
```Bash
az group create \
  --name $RG_NETWORK \
  --location $LOCATION
```

```Bash
az group create \
  --name $RG_WORKLOAD \
  --location $LOCATION
```
### Create VNet and initial AppGW Subnet
```Bash
az network vnet create \
  --resource-group $RG_NETWORK \
  --name $VNET_NAME \
  --address-prefixes 10.0.0.0/16 \
  --subnet-name subnet-appgw \
  --subnet-prefixes 10.0.1.0/24
```

## 3. Subnets Creation
 Web Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --address-prefixes 10.0.2.0/24
```

 API Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --address-prefixes 10.0.3.0/24
```

 Management Subnet
```Bash
az network vnet subnet create \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --address-prefixes 10.0.4.0/24
```

## 4. Network Security Groups (NSG) Creation
```Bash
az network nsg create --resource-group $RG_NETWORK --name nsg-appgw --location $LOCATION
az network nsg create --resource-group $RG_NETWORK --name nsg-backend-a --location $LOCATION
az network nsg create --resource-group $RG_NETWORK --name nsg-backend-b --location $LOCATION
az network nsg create --resource-group $RG_NETWORK --name nsg-mgmt --location $LOCATION
```

## 5. NSG Subnet Association
```Bash
az network vnet subnet update \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-appgw \
  --network-security-group nsg-appgw
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-backend-a \
  --network-security-group nsg-backend-a
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-backend-b \
  --network-security-group nsg-backend-b
```
```Bash
az network vnet subnet update \
  --resource-group $RG_NETWORK \
  --vnet-name $VNET_NAME \
  --name subnet-mgmt \
  --network-security-group nsg-mgmt
```
---

## 6. Public IP Reservation
```Bash
az network public-ip create \
  --resource-group $RG_NETWORK \
  --name $PIP_NAME \
  --location $LOCATION \
  --sku Standard \
  --allocation-method Static
```
---

# ✅ Phase 1 — Vérification

## Vérification de l'association sous-réseau/NSG
```Bash
az network vnet subnet list \
  --resource-group $RG_NETWORK \
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

---
## screenshot
resources :

<img width="973" height="216" alt="Capture d&#39;écran 2026-09-07 131350" src="https://github.com/user-attachments/assets/46f7b3dc-59c8-4e8f-a68e-dc83b577bbb8" />

---

# Phase 2. Règles NSG

## 1. nsg-appgw
```Bash
RG_NETWORK="grp_tpaz104-lab"
VNET_NAME="vnet_tpaz104-lab"

NSG_APPGW="nsg-appgw"
APPGW_SUBNET="10.0.1.0/24"
MGMT_SUBNET_PREFIX="10.0.4.0/24"

MGMT_SUBNET_NAME="subnet-mgmt"
APPGW_PRIVATE_IP="10.0.1.10"
PRIVATE_LISTENER_PORT="8080"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-Internet-To-Public-Listeners \
  --priority 100 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix Internet \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-ranges 80 443

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-Mgmt-To-Private-Listener-8080 \
  --priority 110 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET_PREFIX" \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_PRIVATE_IP" \
  --destination-port-range "$PRIVATE_LISTENER_PORT"

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-GatewayManager-Inbound \
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix GatewayManager \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range 65200-65535

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-AzureLoadBalancer-Inbound \
  --priority 130 \
  --direction Inbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix AzureLoadBalancer \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'
```

## OUTBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-VNet-Outbound \
  --priority 100 \
  --direction Outbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix VirtualNetwork \
  --destination-port-range '*'

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-Internet-Outbound \
  --priority 110 \
  --direction Outbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix '*' \
  --source-port-range '*' \
  --destination-address-prefix Internet \
  --destination-port-range '*'
```
## vérifier le résultat avec
```Bash
az network nsg rule list \
  --resource-group "$RG_NETWORK" \
  --nsg-name nsg-appgw \
  --query "[].{Name:name, Priority:priority, Direction:direction, Access:access, Source:sourceAddressPrefix, Dest:destinationAddressPrefix, DestPort:destinationPortRange}" \
  --output table
```
## résultat :
```Bash
Name                                 Priority    Direction    Access    Source             Dest            DestPort
-----------------------------------  ----------  -----------  --------  -----------------  --------------  -----------
Allow-Internet-To-Public-Listeners   100         Inbound      Allow     Internet           *
Allow-GatewayManager-Inbound         120         Inbound      Allow     GatewayManager     *               65200-65535
Allow-AzureLoadBalancer-Inbound      130         Inbound      Allow     AzureLoadBalancer  *               *
Allow-Mgmt-To-Private-Listener-8080  110         Inbound      Allow     10.0.4.0/24        10.0.1.10       8080
Allow-VNet-Outbound                  100         Outbound     Allow     *                  VirtualNetwork  *
Allow-Internet-Outbound              110         Outbound     Allow     *                  Internet        *
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
  --nsg-name nsg-mgmt \
  --name Allow-HTTP-To-AppGW-PrivateFrontend \
  --priority 110 \
  --direction Outbound \
  --access Allow \
  --protocol Tcp \
  --source-address-prefix "$MGMT_SUBNET" \
  --source-port-range '*' \
  --destination-address-prefix "$APPGW_PRIVATE_IP" \
  --destination-port-range 8080

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
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
  --resource-group "$RG_NETWORK" \
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
Allow-HTTP-To-AppGW-PrivateFrontend  110         Outbound     Allow     10.0.4.0/24  10.0.1.10                8080
Deny-All-Outbound                    4096        Outbound     Deny      *            *                        *
```
---

# Phase 3. Fichiers cloud-init hors ligne
## 📄 Rôle des fichiers Cloud-Init (`cloud-init-web.yaml` & `cloud-init-api.yaml`)

Ces fichiers permettent d'automatiser le **bootstrap hors ligne** (*zero-egress*) des instances lors du déploiement des **Virtual Machine Scale Sets (VMSS)**. 

Comme les sous-réseaux backend n'ont aucun accès à Internet (pas de NAT Gateway ni d'IP publique), ces scripts s'appuient uniquement sur les dépendances préinstallées dans l'image **Ubuntu Server 24.04 LTS** (comme `python3` et `systemd`) sans exécuter de commande `apt update` ou `apt install`.

###  `cloud-init-web.yaml` — Backend Web
* **Création de la structure :** Génère le répertoire `/srv/az104/web` et y injecte une page `index.html` contenant la chaîne de caractères `OK-WEB`.
* **Service Systemd (`az104-web.service`) :** Configure et active un serveur HTTP minimaliste via le module natif Python (`python3 -m http.server 80`).
* **Comportement :** Écoute sur le port 80 et sert la page racine `/` pour répondre aux sondes de santé et aux requêtes d'Aag.

###  `cloud-init-api.yaml` — Backend API
* **Structure d'arborescence :** Génère les répertoires et fichiers nécessaires pour simuler une API routée par chemin (*path-based routing*) :
  * `/srv/az104/api/index.html` $\rightarrow$ Renvoie `OK-API-ROOT`
  * `/srv/az104/api/api/index.html` $\rightarrow$ Renvoie `OK-API` (réponse sur la route `/api/`)
  * `/srv/az104/api/api/health` $\rightarrow$ Renvoie `OK-API-HEALTHY` (utilisé par la sonde de santé personnalisée de l'Application Gateway)
* **Service Systemd (`az104-api.service`) :** Démarre le serveur HTTP Python sur le port 80 ciblant le dossier `/srv/az104/api`.

###  Fonctionnement du service Systemd
Les deux configurations injectent un service Systemd garantissant la haute disponibilité locale de l'application :
* **Départ automatique :** Le service démarre dès que le réseau est prêt (`After=network-online.target`).
* **Autoréparation :** Option `Restart=always` avec un délai de 3 secondes (`RestartSec=3`) pour relancer le serveur web automatiquement en cas de crash.
---

## 1. Contenu des fichiers

### Commande de création

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
-rw-r--r-- 1 nicolas nicolas 2.7K moi jour heure /home/nicolas/appgw.pfx
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

# Phase 5 — Déploiement de l’Application Gateway avec Bicep

Les pools `pool-web` et `pool-api` sont créés vides par le template Bicep.  
Aucun backend fictif, aucune règle `rule1` et aucun objet bootstrap ne sont créés dans cette phase.  
La policy commence en mode Detection, puis sera basculée en Prevention dans une étape ultérieure.  
Le lab utilise OWASP CRS 3.2 afin de reproduire un scénario pédagogique de détection SQL injection.  
En production, la version de managed ruleset recommandée par Microsoft au moment du déploiement doit être privilégiée.  

## 1. Variables
```Bash
RG_NETWORK="grp_tpaz104-lab"
RG_WORKLOAD="grp_tpaz104-lab2"
LOCATION="westeurope"

VNET_NAME="vnet_tpaz104-lab"
APPGW_SUBNET_NAME="subnet-appgw"
MGMT_SUBNET_NAME="subnet-mgmt"

APPGW_NAME="appgw-lab"
PIP_NAME="pip-appgw"
WAF_POLICY_NAME="waf-policy-lab"
APPGW_PRIVATE_IP="10.0.1.10"

POOL_WEB_NAME="pool-web"
POOL_API_NAME="pool-api"

PROBE_WEB_NAME="probe-web"
PROBE_API_NAME="probe-api"

HTTP_SETTING_WEB="http-setting-web"
HTTP_SETTING_API="http-setting-api"

PORT_HTTP_NAME="port-80"
PORT_HTTPS_NAME="port-443"
PORT_PRIVATE_HTTP_NAME="port-8080"
PRIVATE_HTTP_PORT=8080

PUBLIC_FRONTEND_IP="public-frontend-ip"
PRIVATE_FRONTEND_IP="private-frontend-ip"

PUBLIC_HTTP_LISTENER="listener-public-http"
PUBLIC_HTTPS_LISTENER="listener-public-https"
PRIVATE_HTTP_LISTENER="listener-private-http"

REDIRECT_HTTP_TO_HTTPS="redirect-http-to-https"

MAP_PUBLIC="map-public"
MAP_PRIVATE="map-private"

RULE_PUBLIC_PATH="rule-public-path"
RULE_REDIRECT_HTTP="rule-redirect-http"
RULE_PRIVATE_PATH="rule-private-path"

PFX_FILE="$HOME/appgw.pfx"
PFX_CERT_NAME="appgw-labSslCert"

APPGW_BICEP_FILE="deploy-appgw.bicep"
APPGW_DEPLOYMENT_NAME="deploy-appgw-complete"
```
### Contrôle
```Bash
printf '%s\n' \
  "RG_NETWORK=$RG_NETWORK" \
  "RG_WORKLOAD=$RG_WORKLOAD" \
  "LOCATION=$LOCATION" \
  "APPGW_NAME=$APPGW_NAME" \
  "PFX_FILE=$PFX_FILE" \
  "APPGW_PRIVATE_IP=$APPGW_PRIVATE_IP"
```

## 2. Récupérer l’ID du subnet App Gateway
```Bash
SUBNET_APPGW_ID=$(az network vnet subnet show \
  --resource-group "$RG_NETWORK" \
  --vnet-name "$VNET_NAME" \
  --name "$APPGW_SUBNET_NAME" \
  --query id \
  --output tsv)

echo "$SUBNET_APPGW_ID"
```
### résultat
```Bash
/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-appgw
```
### Contrôle du subnet et du NSG associé
```Bash
az network vnet subnet show \
  --ids "$SUBNET_APPGW_ID" \
  --query "{Subnet:name,Prefix:addressPrefix,NSG:networkSecurityGroup.id,Delegations:delegations}" \
  --output jsonc
```
### résultat
```Bash
  "Delegations": [],
  "NSG": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-appgw",
  "Prefix": "10.0.1.0/24",
  "Subnet": "subnet-appgw"
```

## 3. Encoder le mot de passe PFX
```Bash
PFX_FILE="$HOME/appgw.pfx"

read -rsp "Mot de passe du certificat appgw.pfx : " PFX_PASSWORD
echo

if [ -z "$PFX_PASSWORD" ]; then
  echo "Erreur : mot de passe PFX vide."
  exit 1
fi

if [ ! -f "$PFX_FILE" ]; then
  echo "Erreur : le fichier $PFX_FILE est introuvable."
  exit 1
fi

PFX_DATA_B64=$(base64 "$PFX_FILE" | tr -d '\r\n')

if [ -z "$PFX_DATA_B64" ]; then
  echo "Erreur : impossible d'encoder le PFX."
  exit 1
else
  echo "Certificat PFX encodé avec succès (${#PFX_DATA_B64} caractères)."
fi
```
Entrer le mot de passe du fichier appgw.pfx
### résultat
```Bash
Mot de passe du certificat appgw.pfx : 
Certificat PFX encodé avec succès (3604 caractères).
```

## 4. Créer le Bicep dans Cloud Shell Editor
Ouvrir Editor dans Azure Cloud Shell => Ctrl+S => deploy-appgw.bicep => Sauvegarder
### Contrôle
```Bash
ls -lh "$APPGW_BICEP_FILE"
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 12K Sep 11 10:17 deploy-appgw.bicep
```
### 1. Ce que contiendra le Bicep
Le fichier déclarera directement ces ressources dans le groupe grp_tpaz104-lab2 :  
pip-appgw  
waf-policy-lab  
appgw-lab  

Et l’Application Gateway contiendra immédiatement :  
pool-web                  vide  
pool-api                  vide  
probe-web                 GET /, HTTP/80  
probe-api                 GET /api/health, HTTP/80  
http-setting-web          HTTP/80 + probe-web  
http-setting-api          HTTP/80 + probe-api  
public-frontend-ip        pip-appgw  
private-frontend-ip       10.0.1.10  
port-80                   80  
port-8080                 8080  
port-443                  443  
listener-public-http      public / 80  
listener-public-https     public / 443 / certificat  
listener-private-http     private / 8080  
redirect-http-to-https    permanent / conserve path et query string  
map-public                défaut Web /api/* API  
map-private               défaut Web /api/* API  
rule-public-path          priorité 100  
rule-redirect-http        priorité 200  
rule-private-path         priorité 300  

### 2. Créer le contenu du fichier deploy-appgw.bicep
Ouvrir Editor dans Azure Cloud Shell, ouvrir deploy-appgw.bicep, puis coller le contenu complet ci-dessous. Sauvegarde avec Ctrl+S.

```Bash
@description('Azure region for all Application Gateway resources.')
param location string

@description('Application Gateway name.')
param applicationGatewayName string

@description('Public IP address resource name.')
param publicIpName string

@description('Full resource ID of the dedicated Application Gateway subnet.')
param appGatewaySubnetId string

@description('Static private frontend IP address in the Application Gateway subnet.')
param privateFrontendIpAddress string

@description('PFX certificate data encoded in Base64.')
@secure()
param sslCertificateData string

@description('Password protecting the PFX certificate.')
@secure()
param sslCertificatePassword string

@description('WAF policy name.')
param wafPolicyName string

@description('SSL certificate object name inside the Application Gateway.')
param sslCertificateName string = 'appgw-labSslCert'

resource publicIp 'Microsoft.Network/publicIPAddresses@2024-07-01' = {
  name: publicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2024-07-01' = {
  name: wafPolicyName
  location: location
  properties: {
    policySettings: {
      state: 'Enabled'
      mode: 'Detection'
      requestBodyCheck: true
      maxRequestBodySizeInKb: 128
      fileUploadLimitInMb: 100
    }
    managedRules: {
      managedRuleSets: [
        {
          ruleSetType: 'OWASP'
          ruleSetVersion: '3.2'
        }
      ]
    }
  }
}

resource appGateway 'Microsoft.Network/applicationGateways@2024-07-01' = {
  name: applicationGatewayName
  location: location
  properties: {
    sku: {
      name: 'WAF_v2'
      tier: 'WAF_v2'
      capacity: 2
    }

    gatewayIPConfigurations: [
      {
        name: 'gateway-ip-config'
        properties: {
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]

    frontendIPConfigurations: [
      {
        name: 'public-frontend-ip'
        properties: {
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
      {
        name: 'private-frontend-ip'
        properties: {
          privateIPAddress: privateFrontendIpAddress
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: appGatewaySubnetId
          }
        }
      }
    ]

frontendPorts: [
  {
    name: 'port-80'
    properties: {
      port: 80
    }
  }
  {
    name: 'port-443'
    properties: {
      port: 443
    }
  }
  {
    name: 'port-8080'
    properties: {
      port: 8080
    }
  }
]

    sslCertificates: [
      {
        name: sslCertificateName
        properties: {
          data: sslCertificateData
          password: sslCertificatePassword
        }
      }
    ]

    backendAddressPools: [
      {
        name: 'pool-web'
        properties: {}
      }
      {
        name: 'pool-api'
        properties: {}
      }
    ]

    probes: [
      {
        name: 'probe-web'
        properties: {
          protocol: 'Http'
          host: '127.0.0.1'
          path: '/'
          port: 80
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
      {
        name: 'probe-api'
        properties: {
          protocol: 'Http'
          host: '127.0.0.1'
          path: '/api/health'
          port: 80
          interval: 30
          timeout: 30
          unhealthyThreshold: 3
          match: {
            statusCodes: [
              '200-399'
            ]
          }
        }
      }
    ]

    backendHttpSettingsCollection: [
      {
        name: 'http-setting-web'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          probe: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/probes',
              applicationGatewayName,
              'probe-web'
            )
          }
        }
      }
      {
        name: 'http-setting-api'
        properties: {
          port: 80
          protocol: 'Http'
          cookieBasedAffinity: 'Disabled'
          requestTimeout: 30
          probe: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/probes',
              applicationGatewayName,
              'probe-api'
            )
          }
        }
      }
    ]

    httpListeners: [
      {
        name: 'listener-public-http'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              applicationGatewayName,
              'public-frontend-ip'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              applicationGatewayName,
              'port-80'
            )
          }
        }
      }
      {
        name: 'listener-public-https'
        properties: {
          protocol: 'Https'
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              applicationGatewayName,
              'public-frontend-ip'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              applicationGatewayName,
              'port-443'
            )
          }
          sslCertificate: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/sslCertificates',
              applicationGatewayName,
              sslCertificateName
            )
          }
        }
      }
      {
        name: 'listener-private-http'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendIPConfigurations',
              applicationGatewayName,
              'private-frontend-ip'
            )
          }
          frontendPort: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/frontendPorts',
              applicationGatewayName,
              'port-8080'
            )
          }
        }
      }
    ]

    redirectConfigurations: [
      {
        name: 'redirect-http-to-https'
        properties: {
          redirectType: 'Permanent'
          targetListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              applicationGatewayName,
              'listener-public-https'
            )
          }
          includePath: true
          includeQueryString: true
        }
      }
    ]

    urlPathMaps: [
      {
        name: 'map-public'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              applicationGatewayName,
              'pool-web'
            )
          }
          defaultBackendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              applicationGatewayName,
              'http-setting-web'
            )
          }
          pathRules: [
            {
              name: 'api-route'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    applicationGatewayName,
                    'pool-api'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    applicationGatewayName,
                    'http-setting-api'
                  )
                }
              }
            }
          ]
        }
      }
      {
        name: 'map-private'
        properties: {
          defaultBackendAddressPool: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendAddressPools',
              applicationGatewayName,
              'pool-web'
            )
          }
          defaultBackendHttpSettings: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
              applicationGatewayName,
              'http-setting-web'
            )
          }
          pathRules: [
            {
              name: 'api-route'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendAddressPools',
                    applicationGatewayName,
                    'pool-api'
                  )
                }
                backendHttpSettings: {
                  id: resourceId(
                    'Microsoft.Network/applicationGateways/backendHttpSettingsCollection',
                    applicationGatewayName,
                    'http-setting-api'
                  )
                }
              }
            }
          ]
        }
      }
    ]

    requestRoutingRules: [
      {
        name: 'rule-public-path'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 100
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              applicationGatewayName,
              'listener-public-https'
            )
          }
          urlPathMap: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/urlPathMaps',
              applicationGatewayName,
              'map-public'
            )
          }
        }
      }
      {
        name: 'rule-redirect-http'
        properties: {
          ruleType: 'Basic'
          priority: 200
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              applicationGatewayName,
              'listener-public-http'
            )
          }
          redirectConfiguration: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/redirectConfigurations',
              applicationGatewayName,
              'redirect-http-to-https'
            )
          }
        }
      }
      {
        name: 'rule-private-path'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 300
          httpListener: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/httpListeners',
              applicationGatewayName,
              'listener-private-http'
            )
          }
          urlPathMap: {
            id: resourceId(
              'Microsoft.Network/applicationGateways/urlPathMaps',
              applicationGatewayName,
              'map-private'
            )
          }
        }
      }
    ]

    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}

output applicationGatewayId string = appGateway.id
output publicIpResourceId string = publicIp.id
output wafPolicyId string = wafPolicy.id
output poolWebId string = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  applicationGatewayName,
  'pool-web'
)
output poolApiId string = resourceId(
  'Microsoft.Network/applicationGateways/backendAddressPools',
  applicationGatewayName,
  'pool-api'
)
```
### vérification
```Bash
ls -lh "$APPGW_BICEP_FILE"
wc -l "$APPGW_BICEP_FILE"
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 12K Sep 11 10:17 deploy-appgw.bicep
479 deploy-appgw.bicep
```

## 5. Compiler le Bicep
```Bash
az bicep build \
  --file "$APPGW_BICEP_FILE"
```
```Bash
The configuration value of bicep.use_binary_from_path has been set to 'false'.
```
### vérification
```Bash
ls -lh deploy-appgw.json
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 15K Sep 11 10:31 deploy-appgw.json
```
<img width="476" height="432" alt="Capture d&#39;écran 2026-09-11 132240" src="https://github.com/user-attachments/assets/3d308c26-867d-41de-92ed-2167ab4f9eae" />


## 6. Vérifier les objets déclarés
```Bash
grep -E \
  'pool-web|pool-api|probe-web|probe-api|http-setting-web|http-setting-api|port-80|port-443|public-frontend-ip|private-frontend-ip|listener-public-http|listener-public-https|listener-private-http|redirect-http-to-https|map-public|map-private|rule-public-path|rule-redirect-http|rule-private-path' \
  deploy-appgw.json
```
### résultat
```Bash
            "name": "public-frontend-ip",
            "name": "private-frontend-ip",
            "name": "port-80",
            "name": "port-443",
            "name": "port-8080",
            "name": "pool-web",
            "name": "pool-api",
            "name": "probe-web",
            "name": "probe-api",
            "name": "http-setting-web",
                "id": "[resourceId('Microsoft.Network/applicationGateways/probes', parameters('applicationGatewayName'), 'probe-web')]"
            "name": "http-setting-api",
                "id": "[resourceId('Microsoft.Network/applicationGateways/probes', parameters('applicationGatewayName'), 'probe-api')]"
            "name": "listener-public-http",
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', parameters('applicationGatewayName'), 'public-frontend-ip')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendPorts', parameters('applicationGatewayName'), 'port-80')]"
            "name": "listener-public-https",
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', parameters('applicationGatewayName'), 'public-frontend-ip')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendPorts', parameters('applicationGatewayName'), 'port-443')]"
            "name": "listener-private-http",
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendIPConfigurations', parameters('applicationGatewayName'), 'private-frontend-ip')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/frontendPorts', parameters('applicationGatewayName'), 'port-8080')]"
            "name": "redirect-http-to-https",
                "id": "[resourceId('Microsoft.Network/applicationGateways/httpListeners', parameters('applicationGatewayName'), 'listener-public-https')]"
            "name": "map-public",
                "id": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-web')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parameters('applicationGatewayName'), 'http-setting-web')]"
                      "id": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-api')]"
                      "id": "[resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parameters('applicationGatewayName'), 'http-setting-api')]"
            "name": "map-private",
                "id": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-web')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parameters('applicationGatewayName'), 'http-setting-web')]"
                      "id": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-api')]"
                      "id": "[resourceId('Microsoft.Network/applicationGateways/backendHttpSettingsCollection', parameters('applicationGatewayName'), 'http-setting-api')]"
            "name": "rule-public-path",
                "id": "[resourceId('Microsoft.Network/applicationGateways/httpListeners', parameters('applicationGatewayName'), 'listener-public-https')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/urlPathMaps', parameters('applicationGatewayName'), 'map-public')]"
            "name": "rule-redirect-http",
                "id": "[resourceId('Microsoft.Network/applicationGateways/httpListeners', parameters('applicationGatewayName'), 'listener-public-http')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/redirectConfigurations', parameters('applicationGatewayName'), 'redirect-http-to-https')]"
            "name": "rule-private-path",
                "id": "[resourceId('Microsoft.Network/applicationGateways/httpListeners', parameters('applicationGatewayName'), 'listener-private-http')]"
                "id": "[resourceId('Microsoft.Network/applicationGateways/urlPathMaps', parameters('applicationGatewayName'), 'map-private')]"
      "value": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-web')]"
      "value": "[resourceId('Microsoft.Network/applicationGateways/backendAddressPools', parameters('applicationGatewayName'), 'pool-api')]"
```

## 7. Déployer seulement après le contrôle
### contrôle explicite du subnet
```Bash
echo "Subnet App Gateway : $SUBNET_APPGW_ID"

if [ -z "$SUBNET_APPGW_ID" ]; then
  echo "Erreur : ID du subnet App Gateway vide."
  exit 1
fi
```
### Valider sans créer de ressource
```Bash
az deployment group validate \
  --resource-group "$RG_WORKLOAD" \
  --template-file "$APPGW_BICEP_FILE" \
  --parameters \
    location="$LOCATION" \
    applicationGatewayName="$APPGW_NAME" \
    publicIpName="$PIP_NAME" \
    appGatewaySubnetId="$SUBNET_APPGW_ID" \
    privateFrontendIpAddress="$APPGW_PRIVATE_IP" \
    wafPolicyName="$WAF_POLICY_NAME" \
    sslCertificateName="$PFX_CERT_NAME" \
    sslCertificateData="$PFX_DATA_B64" \
    sslCertificatePassword="$PFX_PASSWORD"
```
### Déployer
```Bash
az deployment group create \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_DEPLOYMENT_NAME" \
  --template-file "$APPGW_BICEP_FILE" \
  --parameters \
    location="$LOCATION" \
    applicationGatewayName="$APPGW_NAME" \
    publicIpName="$PIP_NAME" \
    appGatewaySubnetId="$SUBNET_APPGW_ID" \
    privateFrontendIpAddress="$APPGW_PRIVATE_IP" \
    wafPolicyName="$WAF_POLICY_NAME" \
    sslCertificateName="$PFX_CERT_NAME" \
    sslCertificateData="$PFX_DATA_B64" \
    sslCertificatePassword="$PFX_PASSWORD"
```
### éffacer les secrets de la session
```Bash
unset PFX_PASSWORD
unset PFX_DATA_B64
```

# ✅ Phase 5 — Vérification
## 1. vérifier l’état de la passerelle
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    Name:name,
    State:provisioningState,
    OperationalState:operationalState,
    SKU:sku.name,
    Capacity:sku.capacity,
    Pools:backendAddressPools[].name,
    Rules:requestRoutingRules[].{
      Name:name,
      Priority:priority,
      Type:ruleType
    }
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Capacity": 2,
  "Name": "appgw-lab",
  "OperationalState": "Running",
  "Pools": [
    "pool-web",
    "pool-api"
  ],
  "Rules": [
    {
      "Name": "rule-public-path",
      "Priority": 100,
      "Type": "PathBasedRouting"
    },
    {
      "Name": "rule-redirect-http",
      "Priority": 200,
      "Type": "Basic"
    },
    {
      "Name": "rule-private-path",
      "Priority": 300,
      "Type": "PathBasedRouting"
    }
  ],
  "SKU": "WAF_v2",
  "State": "Succeeded"
}
```

## 2. IP publique
```Bash
az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PIP_NAME" \
  --query "{
    Name:name,
    IP:ipAddress,
    SKU:sku.name,
    Allocation:publicIPAllocationMethod,
    AssociatedTo:ipConfiguration.id
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Allocation": "Static",
  "AssociatedTo": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip",
  "IP": "XXX.XXX.XXX.XXX",
  "Name": "pip-appgw",
  "SKU": "Standard"
}
```
## 3. vérification des Frontends, ports et listeners
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    Frontends:frontendIPConfigurations[].{
      Name:name,
      PublicIP:publicIPAddress.id,
      PrivateIP:privateIPAddress,
      Allocation:privateIPAllocationMethod
    },
    Ports:frontendPorts[].{
      Name:name,
      Port:port
    },
    Listeners:httpListeners[].{
      Name:name,
      Protocol:protocol,
      FrontendIPId:frontendIPConfiguration.id,
      FrontendPortId:frontendPort.id,
      CertificateId:sslCertificate.id
    }
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Frontends": [
    {
      "Allocation": "Dynamic",
      "Name": "public-frontend-ip",
      "PrivateIP": null,
      "PublicIP": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/publicIPAddresses/pip-appgw"
    },
    {
      "Allocation": "Static",
      "Name": "private-frontend-ip",
      "PrivateIP": "10.0.1.10",
      "PublicIP": null
    }
  ],
  "Listeners": [
    {
      "CertificateId": null,
      "FrontendIPId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip",
      "FrontendPortId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-80",
      "Name": "listener-public-http",
      "Protocol": "Http"
    },
    {
      "CertificateId": "/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/sslCertificates/appgw-labSslCert",
      "FrontendIPId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip",
      "FrontendPortId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-443",
      "Name": "listener-public-https",
      "Protocol": "Https"
    },
    {
      "CertificateId": null,
      "FrontendIPId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/private-frontend-ip",
      "FrontendPortId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-8080",
      "Name": "listener-private-http",
      "Protocol": "Http"
    }
  ],
  "Ports": [
    {
      "Name": "port-80",
      "Port": 80
    },
    {
      "Name": "port-443",
      "Port": 443
    },
    {
      "Name": "port-8080",
      "Port": 8080
    }
  ]
}
```
## 4. vérification waf-policy
```Bash
az network application-gateway waf-policy show \
  --resource-group "$RG_WORKLOAD" \
  --name "$WAF_POLICY_NAME" \
  --query "{
    Name:name,
    State:policySettings.state,
    Mode:policySettings.mode,
    RequestBodyCheck:policySettings.requestBodyCheck,
    RuleSets:managedRules.managedRuleSets[].{
      Type:ruleSetType,
      Version:ruleSetVersion
    }
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Mode": "Detection",
  "Name": "waf-policy-lab",
  "RequestBodyCheck": true,
  "RuleSets": [
    {
      "Type": "OWASP",
      "Version": "3.2"
    }
  ],
  "State": "Enabled"
}
```
## 5. vérification de Path maps et redirection
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    Redirects:redirectConfigurations[].{
      Name:name,
      Type:redirectType,
      TargetListenerId:targetListener.id,
      IncludePath:includePath,
      IncludeQueryString:includeQueryString
    },
    PathMaps:urlPathMaps[].{
      Name:name,
      DefaultPoolId:defaultBackendAddressPool.id,
      DefaultSettingId:defaultBackendHttpSettings.id,
      Paths:pathRules[].{
        Name:name,
        Patterns:paths,
        PoolId:backendAddressPool.id,
        SettingId:backendHttpSettings.id
      }
    }
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "PathMaps": [
    {
      "DefaultPoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
      "DefaultSettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
      "Name": "map-public",
      "Paths": [
        {
          "Name": "api-route",
          "Patterns": [
            "/api/*"
          ],
          "PoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
          "SettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api"
        }
      ]
    },
    {
      "DefaultPoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
      "DefaultSettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
      "Name": "map-private",
      "Paths": [
        {
          "Name": "api-route",
          "Patterns": [
            "/api/*"
          ],
          "PoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
          "SettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api"
        }
      ]
    }
  ],
  "Redirects": [
    {
      "IncludePath": true,
      "IncludeQueryString": true,
      "Name": "redirect-http-to-https",
      "TargetListenerId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/httpListeners/listener-public-https",
      "Type": "Permanent"
    }
  ]
}
```
## 6. show-backend-health
```Bash
az network application-gateway show-backend-health \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --output jsonc
```
### résultat
```Bash
{
  "backendAddressPools": [
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": []
        }
      ]
    },
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": []
        }
      ]
    }
  ]
}
```
---

# Phase 6. VMSS Web/API, Jumpbox et Autoscale

Phase 6 — VMSS  
  ├── VMSS Web associé à pool-web  
  ├── VMSS API associé à pool-api  
  ├── Jumpbox privée  
  └── Autoscale  

Pour être déterministe, la Phase 6 doit créer les deux VMSS avec Bicep, en attachant explicitement leurs IP configurations aux pools pool-web et pool-api  
association dynamique des VMSS aux pools Application Gateway, puis configuration de l'Autoscale.  
Le minimum Autoscale est fixé à une instance pour limiter le coût.  
Lorsqu’un scale-in a lieu, la disponibilité du backend n’est plus redondante ; il s’agit d’un compromis pédagogique et économique.  

## 1. Variables
```Bash
RG_NETWORK="grp_tpaz104-lab"
RG_WORKLOAD="grp_tpaz104-lab2"
LOCATION="westeurope"

VNET_NAME="vnet_tpaz104-lab"

APPGW_NAME="appgw-lab"
POOL_WEB_NAME="pool-web"
POOL_API_NAME="pool-api"

VMSS_WEB_NAME="vmss-web"
VMSS_API_NAME="vmss-api"

JUMPBOX_NAME="vm-jumpbox"
ADMIN_USER="azureuser"

SKU_VMSS="Standard_D2als_v7"
SKU_JUMPBOX="Standard_D2als_v7"

IMAGE_PUBLISHER="Canonical"
IMAGE_OFFER="ubuntu-24_04-lts"
IMAGE_SKU="server"
IMAGE_VERSION="latest"

CLOUD_INIT_WEB="cloud-init-web.yaml"
CLOUD_INIT_API="cloud-init-api.yaml"

VMSS_BICEP_FILE="deploy-vmss.bicep"
VMSS_DEPLOYMENT_NAME="deploy-vmss-web-api"
```

## 2. Récupérer les IDs nécessaires
```Bash
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

POOL_WEB_ID=$(az network application-gateway address-pool show \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$POOL_WEB_NAME" \
  --query id \
  --output tsv)

POOL_API_ID=$(az network application-gateway address-pool show \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$POOL_API_NAME" \
  --query id \
  --output tsv)

for VARIABLE in \
  SUBNET_WEB_ID \
  SUBNET_API_ID \
  SUBNET_MGMT_ID \
  POOL_WEB_ID \
  POOL_API_ID
do
  if [ -z "${!VARIABLE:-}" ]; then
    echo "Erreur : variable vide : $VARIABLE"
    exit 1
  fi
done

printf '%s\n' \
  "SUBNET_WEB_ID=$SUBNET_WEB_ID" \
  "SUBNET_API_ID=$SUBNET_API_ID" \
  "SUBNET_MGMT_ID=$SUBNET_MGMT_ID" \
  "POOL_WEB_ID=$POOL_WEB_ID" \
  "POOL_API_ID=$POOL_API_ID"
```
### résultat
```Bash
SUBNET_WEB_ID=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-backend-a
SUBNET_API_ID=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-backend-b
SUBNET_MGMT_ID=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-mgmt
POOL_WEB_ID=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web
POOL_API_ID=/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api
```
<img width="1715" height="119" alt="Capture d&#39;écran 2026-09-10 110118" src="https://github.com/user-attachments/assets/7abdae45-f5f7-46a2-a0de-6880b65718c2" />

## 3. Encoder le cloud-init en Base64
Dans un template ARM/Bicep, customData doit être Base64
```Bash
for FILE in "$CLOUD_INIT_WEB" "$CLOUD_INIT_API"; do
  if [ ! -f "$FILE" ]; then
    echo "Erreur : fichier cloud-init introuvable : $FILE"
    exit 1
  fi
done

CLOUD_INIT_WEB_B64=$(base64 -w 0 "$CLOUD_INIT_WEB")
CLOUD_INIT_API_B64=$(base64 -w 0 "$CLOUD_INIT_API")

for VARIABLE in CLOUD_INIT_WEB_B64 CLOUD_INIT_API_B64; do
  if [ -z "${!VARIABLE:-}" ]; then
    echo "Erreur : échec d'encodage : $VARIABLE"
    exit 1
  fi
done

printf '%s\n' \
  "Cloud-init Web encodé : ${#CLOUD_INIT_WEB_B64} caractères" \
  "Cloud-init API encodé : ${#CLOUD_INIT_API_B64} caractères"
```
### résultat
```Bash
Cloud-init Web encodé : 884 caractères
Cloud-init API encodé : 1120 caractères
```
<img width="398" height="50" alt="Capture d&#39;écran 2026-09-11 160524" src="https://github.com/user-attachments/assets/48034dee-a5bf-4d5d-9e14-3ea8e9dfc8f8" />

## 4. Créer le template Bicep
Crée un fichier nommé deploy-vmss.bicep  
Ce template ne définit volontairement :  
    aucune publicIPAddressConfiguration  
    aucune loadBalancerBackendAddressPools  
    aucun networkSecurityGroup au niveau NIC  
    aucune ressource Microsoft.Network/loadBalancers.  
```Bash
cat <<'EOF' > deploy-vmss.bicep
@description('Azure region for the two VM Scale Sets.')
param location string

@description('Name of the Web VM Scale Set.')
param vmssWebName string

@description('Name of the API VM Scale Set.')
param vmssApiName string

@description('Administrator username for VMSS instances.')
param adminUsername string

@secure()
@description('Administrator password for VMSS instances.')
param adminPassword string

@description('Ubuntu Marketplace image reference.')
param imageReference object

@description('VM size for both VMSS.')
param vmSku string

@description('Full resource ID of subnet-backend-a.')
param subnetWebId string

@description('Full resource ID of subnet-backend-b.')
param subnetApiId string

@description('Full resource ID of Application Gateway backend pool pool-web.')
param poolWebId string

@description('Full resource ID of Application Gateway backend pool pool-api.')
param poolApiId string

@secure()
@description('Base64-encoded cloud-init content for the Web VMSS.')
param customDataWeb string

@secure()
@description('Base64-encoded cloud-init content for the API VMSS.')
param customDataApi string

resource vmssWeb 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: vmssWebName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    orchestrationMode: 'Uniform'
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'web'
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: customDataWeb
        linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: imageReference
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-web'
            properties: {
              primary: true
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'ipconfig-web'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetWebId
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: poolWebId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

resource vmssApi 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: vmssApiName
  location: location
  sku: {
    name: vmSku
    tier: 'Standard'
    capacity: 1
  }
  properties: {
    orchestrationMode: 'Uniform'
    overprovision: false
    upgradePolicy: {
      mode: 'Manual'
    }
    virtualMachineProfile: {
      osProfile: {
        computerNamePrefix: 'api'
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: customDataApi
        linuxConfiguration: {
          disablePasswordAuthentication: false
          provisionVMAgent: true
        }
      }
      storageProfile: {
        imageReference: imageReference
        osDisk: {
          createOption: 'FromImage'
          caching: 'ReadWrite'
          managedDisk: {
            storageAccountType: 'Standard_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaceConfigurations: [
          {
            name: 'nic-api'
            properties: {
              primary: true
              enableIPForwarding: false
              ipConfigurations: [
                {
                  name: 'ipconfig-api'
                  properties: {
                    primary: true
                    subnet: {
                      id: subnetApiId
                    }
                    applicationGatewayBackendAddressPools: [
                      {
                        id: poolApiId
                      }
                    ]
                  }
                }
              ]
            }
          }
        ]
      }
    }
  }
}

output vmssWebId string = vmssWeb.id
output vmssApiId string = vmssApi.id
EOF
```
### Vérification
```Bash
ls -lh deploy-vmss.bicep
wc -l "$VMSS_BICEP_FILE"
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 4.3K Sep 11 14:06 deploy-vmss.bicep
176 deploy-vmss.bicep
```

## 5. Valider le fichier Bicep
```Bash
az bicep build \
  --file "$VMSS_BICEP_FILE"

ls -lh deploy-vmss.json
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 6.8K Sep 11 14:07 deploy-vmss.json
```
### Contrôles de l'absence de  Load Balancer et d'IP public :
```Bash
if grep -Eqi \
  'Microsoft\.Network/loadBalancers|Microsoft\.Network/publicIPAddresses|publicIPAddressConfiguration|loadBalancerBackendAddressPools' \
  deploy-vmss.json
then
  echo "Erreur : une ressource ou une association réseau interdite a été détectée."
  exit 1
fi

echo "OK : aucun Load Balancer ni Public IP dans le template."
```

## 6. Déployer les VMSS Web et API
Saisis le mot de passe, sans l’afficher :
```Bash
read -rsp "Mot de passe local des VMSS : " ADMIN_PASSWORD
echo

if [ -z "$ADMIN_PASSWORD" ]; then
  echo "Erreur : mot de passe vide."
  exit 1
fi
```
### contrôles avant déploiment
```Bash
az deployment group validate \
  --resource-group "$RG_WORKLOAD" \
  --template-file "$VMSS_BICEP_FILE" \
  --parameters \
    location="$LOCATION" \
    vmssWebName="$VMSS_WEB_NAME" \
    vmssApiName="$VMSS_API_NAME" \
    adminUsername="$ADMIN_USER" \
    adminPassword="$ADMIN_PASSWORD" \
    vmSku="$SKU_VMSS" \
    imageReference="{\"publisher\":\"$IMAGE_PUBLISHER\",\"offer\":\"$IMAGE_OFFER\",\"sku\":\"$IMAGE_SKU\",\"version\":\"$IMAGE_VERSION\"}" \
    subnetWebId="$SUBNET_WEB_ID" \
    subnetApiId="$SUBNET_API_ID" \
    poolWebId="$POOL_WEB_ID" \
    poolApiId="$POOL_API_ID" \
    customDataWeb="$CLOUD_INIT_WEB_B64" \
    customDataApi="$CLOUD_INIT_API_B64"
```
Seulement si cette validation retourne "provisioningState : Succeeded", lancer le create.
### Déploiment :
Elle automatise en une seule opération la création des deux VMSS (Web et API), leur attachement aux subnets et aux pools de l'Application Gateway, ainsi que leur configuration zero-egress via Cloud-Init.
```Bash
az deployment group create \
  --resource-group "$RG_WORKLOAD" \
  --name "$VMSS_DEPLOYMENT_NAME" \
  --template-file "$VMSS_BICEP_FILE" \
  --parameters \
    location="$LOCATION" \
    vmssWebName="$VMSS_WEB_NAME" \
    vmssApiName="$VMSS_API_NAME" \
    adminUsername="$ADMIN_USER" \
    adminPassword="$ADMIN_PASSWORD" \
    vmSku="$SKU_VMSS" \
    imageReference="{\"publisher\":\"$IMAGE_PUBLISHER\",\"offer\":\"$IMAGE_OFFER\",\"sku\":\"$IMAGE_SKU\",\"version\":\"$IMAGE_VERSION\"}" \
    subnetWebId="$SUBNET_WEB_ID" \
    subnetApiId="$SUBNET_API_ID" \
    poolWebId="$POOL_WEB_ID" \
    poolApiId="$POOL_API_ID" \
    customDataWeb="$CLOUD_INIT_WEB_B64" \
    customDataApi="$CLOUD_INIT_API_B64"
```
### facultatif : supprimer les variables sensibles ou encombrantes
```Bash
unset ADMIN_PASSWORD
unset CLOUD_INIT_WEB_B64
unset CLOUD_INIT_API_B64
```

## 7.Vérifier les VMSS et leur association App Gateway
###  Vérifier les VMSS :
```Bash
az vmss list \
  --resource-group "$RG_WORKLOAD" \
  --query "[].{
    Name:name,
    Mode:orchestrationMode,
    UpgradeMode:upgradePolicy.mode,
    Capacity:sku.capacity,
    SKU:sku.name,
    State:provisioningState
  }" \
  --output table
```
### résultat
```Bash
Name      Mode     UpgradeMode    Capacity    SKU                State
--------  -------  -------------  ----------  -----------------  ---------
vmss-api  Uniform  Manual         1           Standard_D2als_v7  Succeeded
vmss-web  Uniform  Manual         1           Standard_D2als_v7  Succeeded
```
<img width="752" height="99" alt="Capture d&#39;écran 2026-09-11 161340" src="https://github.com/user-attachments/assets/7dbd58a6-3a0e-4664-95cb-1cc5d051b511" />

### Vérifier les profils réseau VMSS
```Bash
for VMSS_NAME in "$VMSS_WEB_NAME" "$VMSS_API_NAME"; do
  echo "=== $VMSS_NAME ==="

  az vmss show \
    --resource-group "$RG_WORKLOAD" \
    --name "$VMSS_NAME" \
    --query "{
      Name:name,
      Mode:orchestrationMode,
      UpgradeMode:upgradePolicy.mode,
      Capacity:sku.capacity,
      Subnet:virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].subnet.id,
      AppGatewayPools:virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools[].id
    }" \
    --output jsonc
done
```
### résultat
```Bash
=== vmss-web ===
{
  "AppGatewayPools": [
    "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web"
  ],
  "Capacity": 1,
  "Mode": "Uniform",
  "Name": "vmss-web",
  "Subnet": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-backend-a",
  "UpgradeMode": "Manual"
}
=== vmss-api ===
{
  "AppGatewayPools": [
    "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api"
  ],
  "Capacity": 1,
  "Mode": "Uniform",
  "Name": "vmss-api",
  "Subnet": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-backend-b",
  "UpgradeMode": "Manual"
}
```
### Vérifier les instances
```Bash.
az vmss list \
  --resource-group "$RG_WORKLOAD" \
  --query "[].{
    Name:name,
    Capacity:sku.capacity,
    State:provisioningState,
    Mode:orchestrationMode
  }" \
  --output table
```
### résultat
```Bash
Name      Capacity    State      Mode
--------  ----------  ---------  -------
vmss-api  1           Succeeded  Uniform
vmss-web  1           Succeeded  Uniform
```
### Vérifier les associations pools
```Bash
az vmss show \
  --resource-group "$RG_WORKLOAD" \
  --name "$VMSS_WEB_NAME" \
  --query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools[].id" \
  --output tsv

az vmss show \
  --resource-group "$RG_WORKLOAD" \
  --name "$VMSS_API_NAME" \
  --query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools[].id" \
  --output tsv
```
### résultat
```Bash
/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web
/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api
```
### show-backend-health
```Bash
az network application-gateway show-backend-health \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "backendAddressPools[].backendHttpSettingsCollection[].servers[].{
    Address:address,
    Health:health,
    ProbeLog:healthProbeLog
  }" \
  --output jsonc
```
### résultat
```Bash
[
  {
    "Address": "10.0.3.4",
    "Health": "Healthy",
    "ProbeLog": "Success. Received 200 status code"
  },
  {
    "Address": "10.0.2.4",
    "Health": "Healthy",
    "ProbeLog": "Success. Received 200 status code"
  }
]
```
<img width="536" height="280" alt="Capture d&#39;écran 2026-09-11 164131" src="https://github.com/user-attachments/assets/caf9aa2b-015e-48ad-a46d-08b99f7939c0" />

### Vérifier l’absence de Load Balancer et PIP VMSS
```Bash
echo "=== Load Balancers du resource group workload ==="

az network lb list \
  --resource-group "$RG_WORKLOAD" \
  --output table

echo
echo "=== Public IPs du resource group workload ==="

az network public-ip list \
  --resource-group "$RG_WORKLOAD" \
  --query "[].{
    Name:name,
    IP:ipAddress,
    SKU:sku.name,
    AssociatedTo:ipConfiguration.id
  }" \
  --output table
```
### résultat
```Bash
Name       IP              SKU       AssociatedTo
---------  --------------  --------  -----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pip-appgw  XX.XX.XX.XX  Standard  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip
```

## 8. Créer la Jumpbox privée
La Jumpbox est créée dans subnet-mgmt sans IP publique.
```Bash
read -rsp "Mot de passe local de la Jumpbox Ubuntu : " JUMPBOX_PASSWORD
echo

if [ -z "${JUMPBOX_PASSWORD:-}" ]; then
  echo "Erreur : mot de passe Jumpbox vide."
  exit 1
fi

if [ -z "${SUBNET_MGMT_ID:-}" ]; then
  echo "Erreur : SUBNET_MGMT_ID est vide."
  exit 1
fi

if [ -z "${RG_WORKLOAD:-}" ] || [ -z "${JUMPBOX_NAME:-}" ] || [ -z "${LOCATION:-}" ]; then
  echo "Erreur : une variable obligatoire est vide."
  exit 1
fi

IMAGE_UBUNTU="Canonical:ubuntu-24_04-lts:server:latest"
SKU_JUMPBOX="Standard_D2als_v7"

echo "Image sélectionnée : $IMAGE_UBUNTU"
echo "Taille sélectionnée : $SKU_JUMPBOX"
echo "Subnet cible        : $SUBNET_MGMT_ID"

az vm create \
  --resource-group "$RG_WORKLOAD" \
  --name "$JUMPBOX_NAME" \
  --location "$LOCATION" \
  --image "$IMAGE_UBUNTU" \
  --size "$SKU_JUMPBOX" \
  --admin-username "$ADMIN_USER" \
  --admin-password "$JUMPBOX_PASSWORD" \
  --authentication-type password \
  --subnet "$SUBNET_MGMT_ID" \
  --public-ip-address "" \
  --nsg ""

unset JUMPBOX_PASSWORD
```
### résultat
```Bash
{
  "fqdns": "",
  "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Compute/virtualMachines/vm-jumpbox",
  "location": "westeurope",
  "macAddress": "38-33-C5-C5-19-0C",
  "powerState": "VM running",
  "privateIpAddress": "10.0.4.4",
  "publicIpAddress": "",
  "resourceGroup": "grp_tpaz104-lab2"
}
```
### activer les diagnostics de démarrage managés
```Bash
az vm boot-diagnostics enable \
  --resource-group "$RG_WORKLOAD" \
  --name "$JUMPBOX_NAME"
```
### Vérifier l’absence d’IP publique de la Jumpbox privée
```Bash
JUMPBOX_NIC_ID=$(az vm show \
  --resource-group "$RG_WORKLOAD" \
  --name "$JUMPBOX_NAME" \
  --query "networkProfile.networkInterfaces[0].id" \
  --output tsv)

az network nic show \
  --ids "$JUMPBOX_NIC_ID" \
  --query "{
    NIC:name,
    PrivateIP:ipConfigurations[0].privateIPAddress,
    PublicIP:ipConfigurations[0].publicIPAddress.id,
    Subnet:ipConfigurations[0].subnet.id,
    NIC_NSG:networkSecurityGroup.id
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "NIC": "vm-jumpboxVMNic",
  "NIC_NSG": null,
  "PrivateIP": "10.0.4.4",
  "PublicIP": null,
  "Subnet": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-mgmt"
}
```

## 9. Configurer Autoscal
Configure une capacité minimale de 1, maximale de 2 et par défaut de 1.  
Les règles CPU sont uniqument une démonstration de configuration.  
### variable
```Bash
AUTOSCALE_WEB_NAME="autoscale-vmss-web"
AUTOSCALE_API_NAME="autoscale-vmss-api"
```
### Récupération dynamique des Resource IDs
```Bash
VMSS_WEB_ID=$(az vmss show --resource-group "$RG_WORKLOAD" --name "$VMSS_WEB_NAME" --query id --output tsv)
VMSS_API_ID=$(az vmss show --resource-group "$RG_WORKLOAD" --name "$VMSS_API_NAME" --query id --output tsv)
```
### autoscale WEB
```Bash
az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource "$VMSS_WEB_ID" \
  --name "$AUTOSCALE_WEB_NAME" \
  --min-count 1 \
  --max-count 2 \
  --count 1

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name "$AUTOSCALE_WEB_NAME" \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1 \
  --cooldown 5

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name "$AUTOSCALE_WEB_NAME" \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1 \
  --cooldown 10
```
### autoscale API
```Bash
az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource "$VMSS_API_ID" \
  --name "$AUTOSCALE_API_NAME" \
  --min-count 1 \
  --max-count 2 \
  --count 1

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name "$AUTOSCALE_API_NAME" \
  --condition "Percentage CPU > 70 avg 5m" \
  --scale out 1 \
  --cooldown 5

az monitor autoscale rule create \
  --resource-group "$RG_WORKLOAD" \
  --autoscale-name "$AUTOSCALE_API_NAME" \
  --condition "Percentage CPU < 30 avg 10m" \
  --scale in 1 \
  --cooldown 10
```
### Vérifier les profils autoscale
```Bash
for AUTOSCALE_NAME in "$AUTOSCALE_WEB_NAME" "$AUTOSCALE_API_NAME"; do
  echo "=== $AUTOSCALE_NAME ==="
  az monitor autoscale show \
    --resource-group "$RG_WORKLOAD" \
    --name "$AUTOSCALE_NAME" \
    --query "{Name:name, Enabled:enabled, RuleCount:length(profiles[0].rules)}" \
    --output jsonc
done
```
### résultat
```Bash
=== autoscale-vmss-web ===
{
  "Enabled": true,
  "Name": "autoscale-vmss-web",
  "RuleCount": 2
}
=== autoscale-vmss-api ===
{
  "Enabled": true,
  "Name": "autoscale-vmss-api",
  "RuleCount": 2
}
nicolas [ ~ ]$ 
```

## 10. Vérifier la santé Application Gateway
```Bash
az network application-gateway show-backend-health \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --output jsonc
```
### résultat
```Bash
{
  "backendAddressPools": [
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": [
            {
              "address": "10.0.3.4",
              "health": "Healthy",
              "healthProbeLog": "Success. Received 200 status code",
              "ipConfiguration": {
                "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-api/virtualMachines/0/networkInterfaces/nic-api/ipConfigurations/ipconfig-api",
                "resourceGroup": "grp_tpaz104-lab2"
              }
            }
          ]
        }
      ]
    },
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": [
            {
              "address": "10.0.2.4",
              "health": "Healthy",
              "healthProbeLog": "Success. Received 200 status code",
              "ipConfiguration": {
                "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-web/virtualMachines/0/networkInterfaces/nic-web/ipConfigurations/ipconfig-web",
                "resourceGroup": "grp_tpaz104-lab2"
              }
            }
          ]
        }
      ]
    }
  ]
}
```


# Phase 7. Configuration de l'App Gateway

Phase 7 — Configuration  
├── Probes de santé  
├── HTTP settings  
├── Port HTTP/80  
├── Listeners publics et privé  
├── Redirection HTTP → HTTPS  
├── URL path maps publique et privée  
├── Règles de routage finales  
└── Suppression du bootstrap  

## 1. Variables et contrôle initial
```Bash
RG_WORKLOAD="grp_tpaz104-lab2"
APPGW_NAME="appgw-lab"
PIP_NAME="pip-appgw"

POOL_WEB_NAME="pool-web"
POOL_API_NAME="pool-api"

PROBE_WEB_NAME="probe-web"
PROBE_API_NAME="probe-api"

HTTP_SETTING_WEB="http-setting-web"
HTTP_SETTING_API="http-setting-api"

PORT_HTTP_NAME="port-80"
PORT_HTTPS_NAME="port-443"

PUBLIC_FRONTEND_IP="public-frontend-ip"
PRIVATE_FRONTEND_IP="private-frontend-ip"

PUBLIC_HTTP_LISTENER="listener-public-http"
PUBLIC_HTTPS_LISTENER="listener-public-https"
PRIVATE_HTTP_LISTENER="listener-private-http"

REDIRECT_HTTP_TO_HTTPS="redirect-http-to-https"

MAP_PUBLIC="map-public"
MAP_PRIVATE="map-private"

RULE_PUBLIC_PATH="rule-public-path"
RULE_REDIRECT_HTTP="rule-redirect-http"
RULE_PRIVATE_PATH="rule-private-path"

RULE_PUBLIC_PATH_PRIORITY=100
RULE_REDIRECT_HTTP_PRIORITY=200
RULE_PRIVATE_PATH_PRIORITY=300
```
Les noms appGatewayFrontendPort et appGatewayFrontendIP sont généralement créés automatiquement par az network application-gateway create.  
### Vérifier les noms avant de continuer.  
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    FrontendIPs:frontendIPConfigurations[].name,
    FrontendPorts:frontendPorts[].name,
    Listeners:httpListeners[].name,
    Rules:requestRoutingRules[].{Name:name, Priority:priority},
    Pools:backendAddressPools[].name
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "FrontendIPs": [
    "public-frontend-ip",
    "private-frontend-ip"
  ],
  "FrontendPorts": [
    "port-80",
    "port-443",
    "port-8080"
  ],
  "Listeners": [
    "listener-public-http",
    "listener-public-https",
    "listener-private-http"
  ],
  "Pools": [
    "pool-web",
    "pool-api"
  ],
  "Rules": [
    {
      "Name": "rule-public-path",
      "Priority": 100
    },
    {
      "Name": "rule-redirect-http",
      "Priority": 200
    },
    {
      "Name": "rule-private-path",
      "Priority": 300
    }
  ]
}
```
Si les noms sont différents, modifie les variables PORT_HTTPS_NAME et PUBLIC_FRONTEND_IP en conséquence

## 2. lister les objets temporaires
```Bash
az network application-gateway address-pool list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --output table

az network application-gateway http-settings list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --output table

az network application-gateway http-listener list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --output table

az network application-gateway rule list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --output table
```
### résultat
```Bash
Name      ProvisioningState    ResourceGroup
--------  -------------------  ----------------
pool-web  Succeeded            grp_tpaz104-lab2
pool-api  Succeeded            grp_tpaz104-lab2
CookieBasedAffinity    DedicatedBackendConnection    Name              PickHostNameFromBackendAddress    Port    Protocol    ProvisioningState    RequestTimeout    ResourceGroup     ValidateCertChainAndExpiry    ValidateSNI
---------------------  ----------------------------  ----------------  --------------------------------  ------  ----------  -------------------  ----------------  ----------------  ----------------------------  -------------
Disabled               False                         http-setting-web  False                             80      Http        Succeeded            30                grp_tpaz104-lab2  True                          True
Disabled               False                         http-setting-api  False                             80      Http        Succeeded            30                grp_tpaz104-lab2  True                          True
Name                   Protocol    ProvisioningState    RequireServerNameIndication    ResourceGroup
---------------------  ----------  -------------------  -----------------------------  ----------------
listener-public-http   Http        Succeeded            False                          grp_tpaz104-lab2
listener-public-https  Https       Succeeded            False                          grp_tpaz104-lab2
listener-private-http  Http        Succeeded            False                          grp_tpaz104-lab2
Name                Priority    ProvisioningState    ResourceGroup     RuleType
------------------  ----------  -------------------  ----------------  ----------------
rule-public-path    100         Succeeded            grp_tpaz104-lab2  PathBasedRouting
rule-redirect-http  200         Succeeded            grp_tpaz104-lab2  Basic
rule-private-path   300         Succeeded            grp_tpaz104-lab2  PathBasedRouting
```

## 3. Créer les probes de santé
Les VMSS doivent être créés, associés aux pools pool-web et pool-api, et leurs services doivent répondre sur HTTP/80.
### Probe Web
```Bash
az network application-gateway probe create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PROBE_WEB_NAME" \
  --protocol Http \
  --host 127.0.0.1 \
  --path / \
  --port 80 \
  --interval 30 \
  --timeout 30 \
  --threshold 3 \
  --match-status-codes 200-399
```
### Probe API
```Bash
az network application-gateway probe create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PROBE_API_NAME" \
  --protocol Http \
  --host 127.0.0.1 \
  --path /api/health \
  --port 80 \
  --interval 30 \
  --timeout 30 \
  --threshold 3 \
  --match-status-codes 200-399
```
### vérification 
```Bash
az network application-gateway probe list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Protocol:protocol,
    Host:host,
    Path:path,
    Port:port,
    Interval:interval,
    Timeout:timeout,
    Threshold:unhealthyThreshold,
    AcceptedStatus:match.statusCodes
  }" \
  --output table
```
### résultat
```Bash
Name       Protocol    Host       Path         Port    Interval    Timeout    Threshold
---------  ----------  ---------  -----------  ------  ----------  ---------  -----------
probe-web  Http        127.0.0.1  /            80      30          30         3
probe-api  Http        127.0.0.1  /api/health  80      30          30         3
```
<img width="897" height="99" alt="Capture d&#39;écran 2026-09-10 120259" src="https://github.com/user-attachments/assets/9d8657e6-e2cd-492f-b394-6f8bcd95f793" />

## 4. Créer les HTTP settings
Chaque pool a un HTTP setting distinct, avec sa probe dédiée.
```Bash
az network application-gateway http-settings create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$HTTP_SETTING_WEB" \
  --port 80 \
  --protocol Http \
  --timeout 30 \
  --probe "$PROBE_WEB_NAME"

az network application-gateway http-settings create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$HTTP_SETTING_API" \
  --port 80 \
  --protocol Http \
  --timeout 30 \
  --probe "$PROBE_API_NAME"
```
### vérification 
```Bash
az network application-gateway http-settings list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Port:port,
    Protocol:protocol,
    Timeout:requestTimeout,
    CookieAffinity:cookieBasedAffinity,
    PickHostNameFromBackend:pickHostNameFromBackendAddress,
    ProbeId:probe.id
  }" \
  --output table
```
### résultat
```Bash
Name              Port    Protocol    Timeout    CookieAffinity    PickHostNameFromBackend    ProbeId
----------------  ------  ----------  ---------  ----------------  -------------------------  --------------------------------------------------------------------------------------------------------------------------------------------------------------
http-setting-web  80      Http        30         Disabled          False                      /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/probes/probe-web
http-setting-api  80      Http        30         Disabled          False                      /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/probes/probe-api
```

## 5. Créer le port HTTP 80
Le port HTTPS/443 existe déjà sous le nom : appGatewayFrontendPort
```Bash
az network application-gateway frontend-port create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PORT_HTTP_NAME" \
  --port 80
```
### vérification 
```Bash
az network application-gateway frontend-port list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Port:port
  }" \
  --output table
```
### résultat
```Bash
Name       Port
---------  ------
port-80    80
port-443   443
port-8080  8080
```
<img width="178" height="120" alt="Capture d&#39;écran 2026-09-14 130517" src="https://github.com/user-attachments/assets/4ff18033-3b93-4844-9329-59fc9233081b" />
### Si le port 443 a un autre nom, mettre à jour :
```Bash
PORT_HTTPS_NAME="<NOM_REEL_DU_PORT_443>"
```

## 6. Vérifier les listeners
Les listeners pour les accès public (HTTP/HTTPS) et privé ont été correctement identifiés et configurés.  
le listener HTTPS public final :  
```text
* **HTTP Public :** `listener-public-http` (IP Publique, `port-80`)
* **HTTPS Public :** `listener-public-https` (IP Publique, `port-443`)
* **HTTP Privé :** `listener-private-http` (IP Privée, `port-8080`)
```
### Vérifier le certificat SSL
```Bash
SSL_CERT_NAME=$(az network application-gateway ssl-cert list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[0].name" \
  --output tsv)

echo "$SSL_CERT_NAME"
```
### Résultat attendu
```text
appgw-labSslCert
```
### Vérifier tous les listeners
```Bash
az network application-gateway http-listener list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Protocol:protocol,
    FrontendIPId:frontendIPConfiguration.id,
    FrontendPortId:frontendPort.id,
    SSLCertificateId:sslCertificate.id,
    State:provisioningState
  }" \
  --output table
```
### Résultat attendu
La commande affiche les IDs ARM complets. Les relations attendues sont :
```Bash
Name                   Protocol    FrontendIPId                                                                                                                                                                                FrontendPortId                                                                                                                                                         State      SSLCertificateId
---------------------  ----------  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------  ---------  ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
listener-public-http   Http        /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip   /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-80    Succeeded
listener-public-https  Https       /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/public-frontend-ip   /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-443   Succeeded  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/sslCertificates/appgw-labSslCert
listener-private-http  Http        /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/private-frontend-ip  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendPorts/port-8080  Succeeded
```

## 7. Créer la redirection HTTP vers HTTPS
La redirection concerne seulement le listener HTTP public sur le port 80.
```Bash
az network application-gateway redirect-config create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$REDIRECT_HTTP_TO_HTTPS" \
  --type Permanent \
  --target-listener "$PUBLIC_HTTPS_LISTENER" \
  --include-path true \
  --include-query-string true
```
### Vérification
```Bash
az network application-gateway redirect-config show \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$REDIRECT_HTTP_TO_HTTPS" \
  --query "{
    Name:name,
    Type:redirectType,
    TargetListenerId:targetListener.id,
    IncludePath:includePath,
    IncludeQueryString:includeQueryString,
    State:provisioningState
  }" \
  --output jsonc
```
### Résultat attendu
```json
{
  "IncludePath": true,
  "IncludeQueryString": true,
  "Name": "redirect-http-to-https",
  "State": null,
  "TargetListenerId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/httpListeners/listener-public-https",
  "Type": "Permanent"
}
```

## 8. Créer les URL path maps
Chaque URL path map utilise la même logique de routage :
| Chemin demandé                       | Destination                        |  
| `/*` ou tout chemin hors `/api/*`    | `pool-web` avec `http-setting-web` |  
| `/api/*`                             | `pool-api` avec `http-setting-api` |  
### Map publique
```Bash
az network application-gateway url-path-map create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$MAP_PUBLIC" \
  --default-address-pool "$POOL_WEB_NAME" \
  --default-http-settings "$HTTP_SETTING_WEB" \
  --rule-name api-route \
  --paths "/api/*" \
  --address-pool "$POOL_API_NAME" \
  --http-settings "$HTTP_SETTING_API"
```
### Map privée
```Bash
az network application-gateway url-path-map create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$MAP_PRIVATE" \
  --default-address-pool "$POOL_WEB_NAME" \
  --default-http-settings "$HTTP_SETTING_WEB" \
  --rule-name api-route \
  --paths "/api/*" \
  --address-pool "$POOL_API_NAME" \
  --http-settings "$HTTP_SETTING_API"
```
### Vérification
```Bash
for MAP in "$MAP_PUBLIC" "$MAP_PRIVATE"; do
  echo "=== $MAP ==="

  az network application-gateway url-path-map show \
    --resource-group "$RG_WORKLOAD" \
    --gateway-name "$APPGW_NAME" \
    --name "$MAP" \
    --query "{
      Name:name,
      DefaultPoolId:defaultBackendAddressPool.id,
      DefaultSettingId:defaultBackendHttpSettings.id,
      PathRules:pathRules[].{
        Name:name,
        Paths:paths,
        PoolId:backendAddressPool.id,
        SettingId:backendHttpSettings.id
      }
    }" \
    --output jsonc
done
```
### Résultat
```Bash
=== map-public ===
{
  "DefaultPoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
  "DefaultSettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
  "Name": "map-public",
  "PathRules": [
    {
      "Name": "api-route",
      "Paths": [
        "/api/*"
      ],
      "PoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
      "SettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api"
    }
  ]
}
=== map-private ===
{
  "DefaultPoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
  "DefaultSettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
  "Name": "map-private",
  "PathRules": [
    {
      "Name": "api-route",
      "Paths": [
        "/api/*"
      ],
      "PoolId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
      "SettingId": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api"
    }
  ]
}
```

## 9. Créer les règles de routage
rule-public-path     → 100  
rule-redirect-http   → 200  
rule-private-path    → 300  
```Bash
az network application-gateway rule list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{Name:name, Priority:priority, Type:ruleType}" \
  --output table
```
### Résultat
```Bash
Name                Priority    Type
------------------  ----------  ----------------
rule-public-path    100         PathBasedRouting
rule-redirect-http  200         Basic
rule-private-path   300         PathBasedRouting
```
### HTTPS public : routage basé sur le chemin
```Bash
az network application-gateway rule update \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "rule-public-path" \
  --http-listener "$PUBLIC_HTTPS_LISTENER" \
  --url-path-map "$MAP_PUBLIC" \
  --address-pool "pool-web" \
  --http-settings "http-setting-web"
```
### HTTP public : redirection permanente vers HTTPS
```Bash
az network application-gateway rule create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$RULE_REDIRECT_HTTP" \
  --rule-type Basic \
  --http-listener "$PUBLIC_HTTP_LISTENER" \
  --redirect-config "$REDIRECT_HTTP_TO_HTTPS" \
  --priority "$RULE_REDIRECT_HTTP_PRIORITY"
```
### HTTP privé : routage basé sur le chemin
```Bash
az network application-gateway rule update \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "rule-private-path" \
  --http-listener "$PRIVATE_HTTP_LISTENER" \
  --url-path-map "$MAP_PRIVATE" \
  --address-pool "pool-web" \
  --http-settings "http-setting-web"
```

# ✅ Phase 7 — Vérification
## 1. Règles finales
```Bash
az network application-gateway rule list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Priority:priority,
    Type:ruleType,
    ListenerId:httpListener.id,
    PathMapId:urlPathMap.id,
    RedirectId:redirectConfiguration.id,
    State:provisioningState
  }" \
  --output table
```
### Résultat
```Bash
Name                Priority    Type              ListenerId                                                                                                                                                                         PathMapId                                                                                                                                                              State      RedirectId
------------------  ----------  ----------------  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------  ---------------------------------------------------------------------------------------------------------------------------------------------------------------------  ---------  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
rule-public-path    100         PathBasedRouting  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/httpListeners/listener-public-https  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/urlPathMaps/map-public   Succeeded
rule-redirect-http  200         Basic             /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/httpListeners/listener-public-http                                                                                                                                                                          Succeeded  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/redirectConfigurations/redirect-http-to-https
rule-private-path   300         PathBasedRouting  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/httpListeners/listener-private-http  /subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/urlPathMaps/map-private  Succeeded
```

## 2. Santé des backends
```Bash
az network application-gateway show-backend-health \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --output jsonc
```
### Résultat
```Bash
{
  "backendAddressPools": [
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-api",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-api",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": [
            {
              "address": "10.0.3.4",
              "health": "Healthy",
              "healthProbeLog": "Success. Received 200 status code",
              "ipConfiguration": {
                "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-api/virtualMachines/0/networkInterfaces/nic-api/ipConfigurations/ipconfig-api",
                "resourceGroup": "grp_tpaz104-lab2"
              }
            }
          ]
        }
      ]
    },
    {
      "backendAddressPool": {
        "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendAddressPools/pool-web",
        "resourceGroup": "grp_tpaz104-lab2"
      },
      "backendHttpSettingsCollection": [
        {
          "backendHttpSettings": {
            "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/backendHttpSettingsCollection/http-setting-web",
            "resourceGroup": "grp_tpaz104-lab2"
          },
          "servers": [
            {
              "address": "10.0.2.4",
              "health": "Healthy",
              "healthProbeLog": "Success. Received 200 status code",
              "ipConfiguration": {
                "id": "/subscriptions/<SUBSCRIPTION_ID>/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Compute/virtualMachineScaleSets/vmss-web/virtualMachines/0/networkInterfaces/nic-web/ipConfigurations/ipconfig-web",
                "resourceGroup": "grp_tpaz104-lab2"
              }
            }
          ]
        }
      ]
    }
  ]
}
```
---

# Phase 8. Tests fonctionnels

## 1. Test de redirection HTTP vers HTTPS
```Bash
curl -I http://<XX.XX.XX.XX>
```
### résultat de redirection HTTP vers HTTPS
```Bash
HTTP/1.1 301 Moved Permanently
Server: Microsoft-Azure-Application-Gateway/v2
Date: Mon, 14 Sep 2026 13:17:41 GMT
Content-Type: text/html
Content-Length: 195
Connection: keep-alive
Location: https://XX.XX.XX.XX/
```
<img width="435" height="183" alt="image" src="https://github.com/user-attachments/assets/29dd29bb-c101-46b4-93b0-e13b3368e789" />


## 2. Tests de requêtes HTTP / HTTPS
```Bash
nicolas [ ~ ]$ curl -I http://XX.XX.XX.XX/
HTTP/1.1 301 Moved Permanently
Server: Microsoft-Azure-Application-Gateway/v2
Date: Mon, 14 Sep 2026 11:37:17 GMT
Content-Type: text/html
Content-Length: 195
Connection: keep-alive
Location: https://XX.XX.XX.XX/
```
<img width="475" height="188" alt="Capture d&#39;écran 2026-09-14 134314" src="https://github.com/user-attachments/assets/fcf587d6-a404-49a6-81bb-2226b6f621e9" />

```Bash
nicolas [ ~ ]$ curl -k -I "https://XX.XX.XX.XX/api/health"
HTTP/1.1 200 OK
Date: Mon, 14 Sep 2026 11:37:51 GMT
Content-Type: application/octet-stream
Content-Length: 15
Connection: keep-alive
Server: SimpleHTTP/0.6 Python/3.12.3
Last-Modified: Mon, 14 Sep 2026 09:32:56 GMT
```
<img width="616" height="191" alt="Capture d&#39;écran 2026-09-14 134503" src="https://github.com/user-attachments/assets/5111bdc2-b0c4-430e-a96e-553a22562e1f" />

```Bash
nicolas [ ~ ]$ curl -k -L "http://XX.XX.XX.XX/"
OK-WEB
```
<img width="505" height="47" alt="Capture d&#39;écran 2026-09-14 135128" src="https://github.com/user-attachments/assets/965cd8f2-f96c-45af-99f0-d7bb5ed0a3b1" />

```Bash
nicolas [ ~ ]$ curl -k -L "http://XX.XX.XX.XX/api/health"
OK-API-HEALTHY
```
<img width="603" height="50" alt="Capture d&#39;écran 2026-09-14 135221" src="https://github.com/user-attachments/assets/22908737-8149-42e0-892d-bd8a5bf7eb7e" />

## 3. Test depuis la jumpboxe en serial
```Bash
azureuser@vm-jumpbox:~$ curl --connect-timeout 5 --max-time 10 -i \
  "http://10.0.1.10:8080/"
HTTP/1.1 200 OK
Date: Mon, 14 Sep 2026 12:39:01 GMT
Content-Type: text/html
Content-Length: 7
Connection: keep-alive
Server: SimpleHTTP/0.6 Python/3.12.3
Last-Modified: Mon, 14 Sep 2026 09:33:17 GMT

OK-WEB
azureuser@vm-jumpbox:~$ curl --connect-timeout 5 --max-time 10 -i \
  "http://10.0.1.10:8080/api/health"
HTTP/1.1 200 OK
Date: Mon, 14 Sep 2026 12:39:20 GMT
Content-Type: application/octet-stream
Content-Length: 15
Connection: keep-alive
Server: SimpleHTTP/0.6 Python/3.12.3
Last-Modified: Mon, 14 Sep 2026 09:32:56 GMT

OK-API-HEALTHY
azureuser@vm-jumpbox:~$ 
```
<img width="760" height="491" alt="Capture d&#39;écran 2026-09-14 144042" src="https://github.com/user-attachments/assets/e5d732e9-8c35-4bde-bad2-e30ce5697baa" />

## 4. connexion ssh vers les VM des VMSS depuis la Jumpboxe
### VMSS WEB
```Bash
azureuser@vm-jumpbox:~$ ssh azureuser@10.0.2.4
The authenticity of host '10.0.2.4 (10.0.2.4)' can't be established.
ED25519 key fingerprint is SHA256:nO988ZRBQLXy+PSQMbfOPYt16pszxTyOeqh9IJiPrvg.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.2.4' (ED25519) to the list of known hosts.
azureuser@10.0.2.4's password: 
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.17.0-1022-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon Sep 14 13:01:45 UTC 2026

  System load:  0.02              Temperature:           49.9 C
  Usage of /:   5.6% of 28.02GB   Processes:             122
  Memory usage: 8%                Users logged in:       0
  Swap usage:   0%                IPv4 address for eth0: 10.0.2.4

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@web000000:~$ ps aux | grep python
root         724  0.0  0.5  32436 21136 ?        Ss   09:32   0:00 /usr/bin/python3 /usr/bin/networkd-dispatcher --run-startup-triggers
root         738  0.0  0.7  39440 31424 ?        Ss   09:32   0:00 /usr/bin/python3 -u /usr/sbin/waagent -daemon
root         793  0.0  0.5 110028 23396 ?        Ssl  09:32   0:00 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
root        1101  0.0  0.5 178092 21064 ?        Ss   09:33   0:01 /usr/bin/python3 -m http.server 80 --directory /srv/az104/web
root        1251  0.0  0.9 413724 37480 ?        Sl   09:35   0:05 /usr/bin/python3 -u bin/WALinuxAgent-2.16.0.2-py3.12.egg -run-exthandlers
azureus+    3013  0.0  0.0   7084  2288 pts/0    S+   13:03   0:00 grep --color=auto python
azureuser@web000000:~$ curl -i http://localhost/
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.12.3
Date: Mon, 14 Sep 2026 13:03:10 GMT
Content-type: text/html
Content-Length: 7
Last-Modified: Mon, 14 Sep 2026 09:33:17 GMT

OK-WEB
azureuser@web000000:~$ 
```
<img width="906" height="487" alt="Capture d&#39;écran 2026-09-14 150533" src="https://github.com/user-attachments/assets/5706b4ce-51e9-4223-91b4-015767bb90da" />

### VMSS API
```Bash
azureuser@vm-jumpbox:~$ ssh azureuser@10.0.3.4
The authenticity of host '10.0.3.4 (10.0.3.4)' can't be established.
ED25519 key fingerprint is SHA256:1qbO97a/FiQiLXjnGW8KcqJRtV2H5Zv9TDGkHGYcWA4.
This key is not known by any other names.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '10.0.3.4' (ED25519) to the list of known hosts.
azureuser@10.0.3.4's password: 
Welcome to Ubuntu 24.04.4 LTS (GNU/Linux 6.17.0-1022-azure x86_64)

 * Documentation:  https://help.ubuntu.com
 * Management:     https://landscape.canonical.com
 * Support:        https://ubuntu.com/pro

 System information as of Mon Sep 14 13:06:14 UTC 2026

  System load:  0.08              Temperature:           49.9 C
  Usage of /:   5.6% of 28.02GB   Processes:             121
  Memory usage: 8%                Users logged in:       0
  Swap usage:   0%                IPv4 address for eth0: 10.0.3.4

Expanded Security Maintenance for Applications is not enabled.

0 updates can be applied immediately.

Enable ESM Apps to receive additional future security updates.
See https://ubuntu.com/esm or run: sudo pro status


The list of available updates is more than a week old.
To check for new updates run: sudo apt update


The programs included with the Ubuntu system are free software;
the exact distribution terms for each program are described in the
individual files in /usr/share/doc/*/copyright.

Ubuntu comes with ABSOLUTELY NO WARRANTY, to the extent permitted by
applicable law.

To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

azureuser@api000000:~$ ps aux | grep python
root         725  0.0  0.5  32436 20828 ?        Ss   09:32   0:00 /usr/bin/python3 /usr/bin/networkd-dispatcher --run-startup-triggers
root         737  0.0  0.7  39444 30968 ?        Ss   09:32   0:00 /usr/bin/python3 -u /usr/sbin/waagent -daemon
root         801  0.0  0.5 110028 23384 ?        Ssl  09:32   0:00 /usr/bin/python3 /usr/share/unattended-upgrades/unattended-upgrade-shutdown --wait-for-signal
root        1103  0.0  0.5 178092 21056 ?        Ss   09:32   0:01 /usr/bin/python3 -m http.server 80 --directory /srv/az104/api
root        1252  0.0  0.9 413724 37448 ?        Sl   09:35   0:05 /usr/bin/python3 -u bin/WALinuxAgent-2.16.0.2-py3.12.egg -run-exthandlers
root        2838  0.6  0.8 118592 33396 ?        Sl   13:06   0:00 /usr/bin/python3 /usr/lib/ubuntu-release-upgrader/check-new-release -q
azureus+    2945  0.0  0.0   7084  2296 pts/0    S+   13:06   0:00 grep --color=auto python
azureuser@api000000:~$ curl -i http://localhost/api/health
HTTP/1.0 200 OK
Server: SimpleHTTP/0.6 Python/3.12.3
Date: Mon, 14 Sep 2026 13:06:53 GMT
Content-type: application/octet-stream
Content-Length: 15
Last-Modified: Mon, 14 Sep 2026 09:32:56 GMT

OK-API-HEALTHY
azureuser@api000000:~$ 
```
<img width="907" height="534" alt="Capture d&#39;écran 2026-09-14 150715" src="https://github.com/user-attachments/assets/9f59de1a-3fbc-4686-9a6c-10efcfcdc4e6" />

## 5. Test depuis un PC local avec Powershell
```Bash
curl.exe -k -L "http://XX.XX.XX.XX/"
```
```Bash
curl.exe -k -L "http://XX.XX.XX.XX/api/health"
```
### résultat
<img width="583" height="79" alt="Capture d&#39;écran 2026-09-14 145344" src="https://github.com/user-attachments/assets/80f9965d-7b67-49e6-9270-311d6cadae7c" />



## 1.
### vérification 
```Bash

```
### résultat
```Bash

```




