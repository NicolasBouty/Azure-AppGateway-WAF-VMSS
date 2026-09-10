
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
APPGW_SUBNET="10.0.1.0/24"
RG_NETWORK="grp_tpaz104-lab"
NSG_APPGW="nsg-appgw"
```
## INBOUND
```Bash
az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
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
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
  --name Allow-GatewayManager-Inbound \
  --priority 110 \
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
  --priority 120 \
  --direction Inbound \
  --access Allow \
  --protocol '*' \
  --source-address-prefix AzureLoadBalancer \
  --source-port-range '*' \
  --destination-address-prefix '*' \
  --destination-port-range '*'

az network nsg rule create \
  --resource-group "$RG_NETWORK" \
  --nsg-name "$NSG_APPGW" \
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
Name                             Priority    Direction    Access    Source             Dest            DestPort
-------------------------------  ----------  -----------  --------  -----------------  --------------  -----------
Allow-Internet-Inbound           100         Inbound      Allow     Internet           10.0.1.0/24
Deny-All-Inbound                 4096        Inbound      Deny      *                  *               *
Allow-GatewayManager-Inbound     110         Inbound      Allow     GatewayManager     *               65200-65535
Allow-AzureLoadBalancer-Inbound  120         Inbound      Allow     AzureLoadBalancer  *               *
Allow-Internet-Outbound          110         Outbound     Allow     *                  Internet        *
Allow-VNet-Outbound              100         Outbound     Allow     *                  VirtualNetwork  *
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
  --destination-port-range 80

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
Allow-HTTP-To-AppGW-PrivateFrontend  110         Outbound     Allow     10.0.4.0/24  10.0.1.10                80
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

# Phase 5. Déploiement de l'Appliquation-Gateway

Phase 5 — Base App Gateway  
  ├── Public IP  
  ├── WAF Policy Detection  
  ├── App Gateway  
  ├── pool-web + pool-api  
  └── frontend privé  

10.0.2.4 est un backend temporaire de bootstrap et doit être supprimé après création des pools VMSS.  
Il ne représente pas une instance VMSS permanente.  
Il sera remplacé par pool-web et pool-api.  
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
APPGW_NAME="appgw-lab"
PIP_NAME="pip-appgw"
WAF_POLICY_NAME="waf-policy-lab"
PFX_FILE="$HOME/appgw.pfx"
PLACEHOLDER_BACKEND="10.0.2.4"
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
  "NSG": "/subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/networkSecurityGroups/nsg-appgw",
  "Prefix": "10.0.1.0/24",
  "Subnet": "subnet-appgw"
```

## 3. Créer l’adresse IP publique de l’Application Gateway
```Bash
az network public-ip create \
    --resource-group "$RG_WORKLOAD" \
    --name "$PIP_NAME" \
    --location "$LOCATION" \
    --sku Standard \
    --allocation-method Static
```
### Vérifier les propriétés
```Bash
az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PIP_NAME" \
  --query "{
    Name:name,
    ResourceGroup:resourceGroup,
    Location:location,
    IP:ipAddress,
    SKU:sku.name,
    Allocation:publicIPAllocationMethod,
    AssociatedTo:ipConfiguration.id || 'Non associe (OK)'
  }" \
  --output jsonc && \
[ -z "$(az network public-ip show --resource-group "$RG_WORKLOAD" --name "$PIP_NAME" --query "ipConfiguration.id" --output tsv)" ] \
  && echo "PIP valide et non associee" \
  || { echo "Erreur : $PIP_NAME est deja associee" ; exit 1 ; }
```
### résultat
```Bash
 {
  "Allocation": "Static",
  "AssociatedTo": "Non associe (OK)",
  "IP": "XX.XX.XX.XX",
  "Location": "westeurope",
  "Name": "pip-appgw",
  "ResourceGroup": "grp_tpaz104-lab2",
  "SKU": "Standard"
}
PIP valide et non associee.
<img width="391" height="208" alt="Capture d&#39;écran 2026-09-10 104954" src="https://github.com/user-attachments/assets/3a6282e2-712f-4e1d-b271-be702c3e336c" />

```
=> PIP ne doit pas être associé
## 4. Créer la WAF Policy en Detection
```Bash
az network application-gateway waf-policy create \
  --resource-group "$RG_WORKLOAD" \
  --name "$WAF_POLICY_NAME" \
  --location "$LOCATION" \
  --type OWASP \
  --version 3.2
```
### Vérifier les propriétés
```Bash
az network application-gateway waf-policy show \
  --resource-group "$RG_WORKLOAD" \
  --name "$WAF_POLICY_NAME" \
  --query "{
    Name:name,
    Location:location,
    Mode:policySettings.mode,
    State:policySettings.state,
    RuleSets:managedRules.managedRuleSets[].{
      Type:ruleSetType,
      Version:ruleSetVersion
    }
  }" \
  --output jsonc
```
### résultat
```Bash
  "Location": "westeurope",
  "Mode": "Detection",
  "Name": "waf-policy-lab",
  "RuleSets": [
    {
      "Type": "OWASP",
      "Version": "3.2"
    }
  ],
  "State": "Disabled"
```
<img width="279" height="281" alt="Capture d&#39;écran 2026-09-10 105201" src="https://github.com/user-attachments/assets/01335621-37f1-4cff-9b18-fd3c6cd6e3b9" />

## 5. Créer l’Application Gateway WAF v2
La commande CLI crée un ensemble minimal d’objets :
frontend public, port 443, certificat, listener HTTPS, HTTP setting, pool backend temporaire et routing rule initiale.
Nous les compléterons ou remplacerons en Phase 7.
### mot de passe du PFX
```Bash
read -rsp "Mot de passe du certificat appgw.pfx : " PFX_PASSWORD
echo
```
### créer le gateway
```Bash
az network application-gateway create \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --location "$LOCATION" \
  --sku WAF_v2 \
  --capacity 2 \
  --subnet "$SUBNET_APPGW_ID" \
  --public-ip-address "$PIP_NAME" \
  --frontend-port 443 \
  --http-settings-port 80 \
  --http-settings-protocol Http \
  --cert-file "$PFX_FILE" \
  --cert-password "$PFX_PASSWORD" \
  --waf-policy "$WAF_POLICY_NAME" \
  --priority 100 \
  --servers "$PLACEHOLDER_BACKEND"
```
### efface immédiatement la variable
```Bash
unset PFX_PASSWORD
```
### Vérifier les propriétés
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{Name:name,State:provisioningState,SKU:sku.name,Location:location,Capacity:sku.capacity}" \
  --output jsonc
```
### résultat
```Bash
{
  "Capacity": 2,
  "Location": "westeurope",
  "Name": "appgw-lab",
  "SKU": "WAF_v2",
  "State": "Succeeded"
}
```
<img width="281" height="168" alt="Capture d&#39;écran 2026-09-10 105259" src="https://github.com/user-attachments/assets/f3393a21-94b5-477a-92c9-1f7010de428e" />

## 6. Vérifier les objets initiaux
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
    FrontendPort:frontendPorts[0].port,
    ListenerProtocol:httpListeners[0].protocol,
    Certificate:sslCertificates[0].name,
    BackendPool:backendAddressPools[0].name,
    BackendIPs:backendAddressPools[0].backendAddresses[].ipAddress,
    BackendPort:backendHttpSettingsCollection[0].port,
    BackendProtocol:backendHttpSettingsCollection[0].protocol,
    RoutingRule:requestRoutingRules[0].name,
    RoutingRulePriority:requestRoutingRules[0].priority,
    WafPolicy:firewallPolicy.id
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "BackendIPs": [
    "10.0.2.4"
  ],
  "BackendPool": "appGatewayBackendPool",
  "BackendPort": 80,
  "BackendProtocol": "Http",
  "Capacity": 2,
  "Certificate": "appgw-labSslCert",
  "FrontendPort": 443,
  "ListenerProtocol": "Https",
  "Name": "appgw-lab",
  "OperationalState": "Running",
  "RoutingRule": "rule1",
  "RoutingRulePriority": 100,
  "SKU": "WAF_v2",
  "State": "Succeeded",
  "WafPolicy": "/subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/waf-policy-lab"
}
```
<img width="1003" height="461" alt="Capture d&#39;écran 2026-09-10 105346" src="https://github.com/user-attachments/assets/f1daf114-2836-41aa-bad2-b5a32b2ba992" />

## 7. Créer les pools backend finaux
```Bash
az network application-gateway address-pool create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name pool-web

az network application-gateway address-pool create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name pool-api
```
### Vérifier les propriétés
```Bash
az network application-gateway address-pool list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Backends:backendAddresses
  }" \
  --output table
```
### résultat
```Bash
Name
---------------------
appGatewayBackendPool
pool-web
pool-api
```
<img width="222" height="117" alt="Capture d&#39;écran 2026-09-10 105433" src="https://github.com/user-attachments/assets/2b3ff22b-49d2-4d72-b127-9898ca455ff3" />

## 8. Ajouter le frontend privé
```Bash
az network application-gateway frontend-ip create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name private-frontend-ip \
  --private-ip-address 10.0.1.10 \
  --subnet "$SUBNET_APPGW_ID"
```
### Vérifier les propriétés
```Bash
az network application-gateway frontend-ip list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    PublicIP:publicIPAddress.id,
    PrivateIP:privateIPAddress,
    Allocation:privateIPAllocationMethod
  }" \
  --output table
```
### résultat
```Bash
Name                  PublicIP                                                                                                                                     Allocation    State      PrivateIP    Subnet
--------------------  -------------------------------------------------------------------------------------------------------------------------------------------  ------------  ---------  -----------  --------------------------------------------------------------------------------------------------------------------------------------------------------------------
appGatewayFrontendIP  /subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/publicIPAddresses/pip-appgw  Dynamic       Succeeded
private-frontend-ip                                                                                                                                                Static        Succeeded  10.0.1.10    /subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab/providers/Microsoft.Network/virtualNetworks/vnet_tpaz104-lab/subnets/subnet-appgw
```

## 9. Active le WAF en Detection
```Bash
az network application-gateway waf-policy policy-setting list \
  --resource-group "$RG_WORKLOAD" \
  --policy-name "$WAF_POLICY_NAME" \
  --output jsonc
```
### active la policy tout en conservant Detection :
```Bash
az network application-gateway waf-policy policy-setting update \
  --resource-group "$RG_WORKLOAD" \
  --policy-name "$WAF_POLICY_NAME" \
  --state Enabled \
  --mode Detection \
  --request-body-check true
```
### vérification
```Bash
az network application-gateway waf-policy policy-setting list \
  --resource-group "$RG_WORKLOAD" \
  --policy-name "$WAF_POLICY_NAME" \
  --query "{
    Mode:mode,
    State:state,
    RequestBodyCheck:requestBodyCheck
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Mode": "Detection",
  "State": "Enabled",
  "RequestBodyCheck": true
}
```
<img width="280" height="116" alt="Capture d&#39;écran 2026-09-10 105804" src="https://github.com/user-attachments/assets/b68b7278-6476-4b8e-bc62-459e66be0e09" />

# ✅ Phase 5 — Vérification
```Bash
echo "=== Public IP du lab ==="
az network public-ip list \
  --query "[].{
    Name:name,
    ResourceGroup:resourceGroup,
    IP:ipAddress,
    SKU:sku.name,
    AssociatedTo:ipConfiguration.id
  }" \
  --output table

echo "=== Application Gateway ==="
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    Name:name,
    State:provisioningState,
    SKU:sku.name,
    WAFPolicy:firewallPolicy.id,
    BackendPools:backendAddressPools[].name,
    FrontendIPs:frontendIPConfigurations[].{
      Name:name,
      PublicIP:publicIPAddress.id,
      PrivateIP:privateIPAddress
    }
  }" \
  --output jsonc

echo "=== WAF Policy ==="
az network application-gateway waf-policy show \
  --resource-group "$RG_WORKLOAD" \
  --name "$WAF_POLICY_NAME" \
  --query "{
    Name:name,
    Mode:policySettings.mode,
    State:policySettings.state
  }" \
  --output table
```
### résultat
```Bash
=== Public IP du lab ===
Name       ResourceGroup     IP              SKU       AssociatedTo
---------  ----------------  --------------  --------  -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
pip-appgw  grp_tpaz104-lab2  XX.XX.XX.XX  Standard  /subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/frontendIPConfigurations/appGatewayFrontendIP
=== Application Gateway ===
{
  "BackendPools": [
    "appGatewayBackendPool",
    "pool-web",
    "pool-api"
  ],
  "FrontendIPs": null,
  "Name": "appgw-lab",
  "SKU": "WAF_v2",
  "State": "Succeeded",
  "WAFPolicy": "/subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies/waf-policy-lab"
}
=== WAF Policy ===
Name            Mode       State
--------------  ---------  --------
waf-policy-lab  Detection  Enabled
```
---

# Phase 6. Déploiement des VMSS

Phase 6 — VMSS  
  ├── VMSS Web associé à pool-web  
  ├── VMSS API associé à pool-api  
  ├── Jumpbox  
  └── Autoscale  

Pour être déterministe, la Phase 6 doit créer les deux VMSS avec Bicep, en attachant explicitement leurs IP configurations aux pools pool-web et pool-api  
association dynamique des VMSS aux pools Application Gateway, puis configuration de l'Autoscale.  
Le minimum Autoscale est fixé à une instance pour limiter le coût.  
Lorsqu’un scale-in a lieu, la disponibilité du backend n’est plus redondante ; il s’agit d’un compromis pédagogique et économique.  

### Prériquis
Déternine si la version Cloud Shell permet réellement de créer un VMSS directement lié à pool-web/pool-api, sans créer de Load Balancer public.
```Bash
az vmss create --help | grep -i -E "app.gateway|backend.pool|load.balancer|public.ip"
```


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
IMAGE_UBUNTU="Canonical:ubuntu-24_04-lts:server:latest"
CLOUD_INIT_WEB="cloud-init-web.yaml"
CLOUD_INIT_API="cloud-init-api.yaml"
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

printf '%s\n' \
  "$SUBNET_WEB_ID" \
  "$SUBNET_API_ID" \
  "$SUBNET_MGMT_ID" \
  "$POOL_WEB_ID" \
  "$POOL_API_ID"
```
### résultat
```Bash
.../resourceGroups/grp_tpaz104-lab/.../subnets/subnet-backend-a
.../resourceGroups/grp_tpaz104-lab/.../subnets/subnet-backend-b
.../resourceGroups/grp_tpaz104-lab/.../subnets/subnet-mgmt
.../resourceGroups/grp_tpaz104-lab2/.../backendAddressPools/pool-web
.../resourceGroups/grp_tpaz104-lab2/.../backendAddressPools/pool-api
```
<img width="1715" height="119" alt="Capture d&#39;écran 2026-09-10 110118" src="https://github.com/user-attachments/assets/a7351634-2be2-4c74-b2a7-8980cf0fd6fd" />

## 3. Encoder le cloud-init en Base64
Dans un template ARM/Bicep, customData doit être Base64
```Bash
CLOUD_INIT_WEB_B64=$(base64 -w 0 "$CLOUD_INIT_WEB")
CLOUD_INIT_API_B64=$(base64 -w 0 "$CLOUD_INIT_API")
```
### Vérification
```Bash
test -n "$CLOUD_INIT_WEB_B64"
test -n "$CLOUD_INIT_API_B64"
echo "Cloud-init Web encodé : ${#CLOUD_INIT_WEB_B64} caractères"
echo "Cloud-init API encodé : ${#CLOUD_INIT_API_B64} caractères"
```
<img width="399" height="51" alt="Capture d&#39;écran 2026-09-10 110329" src="https://github.com/user-attachments/assets/12e37106-3838-40f2-8a47-66a5a0a0f7a2" />

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

@description('Base64 encoded cloud-init content for the Web VMSS.')
param customDataWeb string

@description('Base64 encoded cloud-init content for the API VMSS.')
param customDataApi string

resource vmssWeb 'Microsoft.Compute/virtualMachineScaleSets@2024-07-01' = {
  name: 'vmss-web'
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
  name: 'vmss-api'
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
```
### résultat
```Bash
-rw-r--r-- 1 nicolas nicolas 4.2K Sep 10 09:04 deploy-vmss.bicep
```
<img width="649" height="27" alt="Capture d&#39;écran 2026-09-10 111529" src="https://github.com/user-attachments/assets/c453da0a-447b-4523-a720-a93affa7c30e" />

## 5. Valider le fichier Bicep
```Bash
az bicep build \
  --file deploy-vmss.bicep
```
### résultat
```Bash
deploy-vmss.json
```
### contrôle facultatif 
Vérifie que le template compilé ne contient aucun Load Balancer ou Public IP :
```Bash
grep -E '"type": "(Microsoft.Network/loadBalancers|Microsoft.Network/publicIPAddresses)"' \
  deploy-vmss.json || true
```
Résultat attendu : aucune ligne.

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
Déploiment :
Elle automatise en une seule opération la création des deux VMSS (Web et API), leur attachement aux subnets et aux pools de l'Application Gateway, ainsi que leur configuration zero-egress via Cloud-Init.
```Bash
az deployment group create \
  --resource-group "$RG_WORKLOAD" \
  --name deploy-vmss-web-api \
  --template-file deploy-vmss.bicep \
  --parameters \
    location="$LOCATION" \
    adminUsername="$ADMIN_USER" \
    adminPassword="$ADMIN_PASSWORD" \
    vmSku="$SKU_VMSS" \
    imageReference="{\"publisher\":\"Canonical\",\"offer\":\"ubuntu-24_04-lts\",\"sku\":\"server\",\"version\":\"latest\"}" \
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

## 7. Vérifier les VMSS et les pools
### 7.1 Vérifier les VMSS :
```Bash
az vmss list \
  --resource-group "$RG_WORKLOAD" \
  --query "[].{
    Name:name,
    Mode:orchestrationMode,
    UpgradeMode:upgradePolicy.mode,
    Capacity:sku.capacity
  }" \
  --output table
```
### résultat
```Bash
Name       Mode     UpgradeMode  Capacity
---------  -------  -----------  --------
vmss-web   Uniform  Manual       1
vmss-api   Uniform  Manual       1
```
<img width="442" height="98" alt="Capture d&#39;écran 2026-09-10 112144" src="https://github.com/user-attachments/assets/70ac8b1e-6178-4a5c-9e38-af00bf6a927d" />

### 7.2 Vérifier l’association App Gateway :
```Bash
az vmss show \
  --resource-group "$RG_WORKLOAD" \
  --name vmss-web \
  --query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools[].id" \
  --output tsv

az vmss show \
  --resource-group "$RG_WORKLOAD" \
  --name vmss-api \
  --query "virtualMachineProfile.networkProfile.networkInterfaceConfigurations[0].ipConfigurations[0].applicationGatewayBackendAddressPools[].id" \
  --output tsv
```
### résultat
```Bash
.../applicationGateways/appgw-lab/backendAddressPools/pool-web
.../applicationGateways/appgw-lab/backendAddressPools/pool-api
```
<img width="603" height="53" alt="Capture d&#39;écran 2026-09-10 112225" src="https://github.com/user-attachments/assets/7552cf50-91ff-4a31-8819-da7a81f12c6b" />
### 7.3 Vérifier l’absence de Load Balancer et de Public IP inattendue
```Bash.
az network lb list \
  --resource-group "$RG_WORKLOAD" \
  --output table

az network public-ip list \
  --query "[].{Name:name,ResourceGroup:resourceGroup,IP:ipAddress}" \
  --output table
```
### résultat
```Bash
Load Balancers :
Aucune ligne

Public IPs :
pip-appgw    grp_tpaz104-lab2    XX.XX.XX.XX
```

## 8. Créer la Jumpbox privée
```Bash
read -rsp "Mot de passe local de la Jumpbox : " JUMPBOX_PASSWORD
echo

if [ -z "$JUMPBOX_PASSWORD" ]; then
  echo "Erreur : mot de passe vide."
  exit 1
fi

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
  --boot-diagnostics ""

unset JUMPBOX_PASSWORD
```
### Vérifier qu’elle a uniquement une IP privée
```Bash
JUMPBOX_NIC_ID=$(az vm show \
  --resource-group "$RG_WORKLOAD" \
  --name vm-jumpbox \
  --query 'networkProfile.networkInterfaces[0].id' \
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
<img width="286" height="166" alt="Capture d&#39;écran 2026-09-10 113320" src="https://github.com/user-attachments/assets/0d093ef1-f319-4485-b413-38383919806d" />

## 9. Configurer Autoscale
Configure une capacité minimale de 1, maximale de 2 et par défaut de 1.  
Les règles CPU sont uniqument une démonstration de configuration.  
```Bash
az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource vmss-web \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-vmss-web \
  --min-count 1 \
  --max-count 2 \
  --count 1

az monitor autoscale create \
  --resource-group "$RG_WORKLOAD" \
  --resource vmss-api \
  --resource-type Microsoft.Compute/virtualMachineScaleSets \
  --name autoscale-vmss-api \
  --min-count 1 \
  --max-count 2 \
  --count 1
```
###  Règles CPU
```Bash
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
```
---

# Phase 7. Configuration de l'App Gateway
Phase 7 — Configuration  
  ├── probes  
  ├── HTTP settings  
  ├── ports  
  ├── listeners  
  ├── redirection HTTP → HTTPS  
  ├── map-public / map-private  
  └── rules  

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
PORT_HTTPS_NAME="appGatewayFrontendPort"
PUBLIC_FRONTEND_IP="appGatewayFrontendIP"
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
```
Les noms appGatewayFrontendPort et appGatewayFrontendIP sont généralement créés automatiquement par az network application-gateway create.  
Vérifier les noms avant de continuer.  
```Bash
az network application-gateway show \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --query "{
    FrontendIPs:frontendIPConfigurations[].name,
    FrontendPorts:frontendPorts[].{Name:name,Port:port},
    Certificates:sslCertificates[].name,
    Listeners:httpListeners[].name,
    Rules:requestRoutingRules[].{Name:name,Priority:priority,Type:ruleType},
    Pools:backendAddressPools[].name
  }" \
  --output jsonc
```
### résultat
```Bash
{
  "Certificates": [
    "appgw-labSslCert"
  ],
  "FrontendIPs": [
    "appGatewayFrontendIP",
    "private-frontend-ip"
  ],
  "FrontendPorts": [
    {
      "Name": "appGatewayFrontendPort",
      "Port": 443
    }
  ],
  "Listeners": [
    "appGatewayHttpListener"
  ],
  "Pools": [
    "appGatewayBackendPool",
    "pool-web",
    "pool-api"
  ],
  "Rules": [
    {
      "Name": "rule1",
      "Priority": 100,
      "Type": "Basic"
    }
  ]
}
```
Si les noms sont différents, modifie les variables PORT_HTTPS_NAME et PUBLIC_FRONTEND_IP en conséquence

## 2. Nettoyer les objets temporaires
La création initiale a normalement créé :
appGatewayBackendPool
appGatewayBackendHttpSettings
appGatewayHttpListener
rule1
### lister les objets temporaires
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
Si les noms générés sont différents, remplacer rule1, appGatewayHttpListener, appGatewayBackendHttpSettings et appGatewayBackendPool par ceux obtenus avec la commande de contrôle
### résultat
```Bash
Name                   ProvisioningState    ResourceGroup
---------------------  -------------------  ----------------
appGatewayBackendPool  Succeeded            grp_tpaz104-lab2
pool-web               Succeeded            grp_tpaz104-lab2
pool-api               Succeeded            grp_tpaz104-lab2
CookieBasedAffinity    DedicatedBackendConnection    Name                           PickHostNameFromBackendAddress    Port    Protocol    ProvisioningState    RequestTimeout    ResourceGroup     ValidateCertChainAndExpiry    ValidateSNI
---------------------  ----------------------------  -----------------------------  --------------------------------  ------  ----------  -------------------  ----------------  ----------------  ----------------------------  -------------
Disabled               False                         appGatewayBackendHttpSettings  False                             80      Http        Succeeded            30                grp_tpaz104-lab2  True                          True
Name                    Protocol    ProvisioningState    RequireServerNameIndication    ResourceGroup
----------------------  ----------  -------------------  -----------------------------  ----------------
appGatewayHttpListener  Https       Succeeded            False                          grp_tpaz104-lab2
Name    Priority    ProvisioningState    ResourceGroup     RuleType
------  ----------  -------------------  ----------------  ----------
rule1   100         Succeeded            grp_tpaz104-lab2  Basic
```

XXXXX A DEPLACER XXXXX
### Supprimer la règle initiale
```Bash
az network application-gateway rule delete \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name rule1
```
### Supprimer le listener HTTPS temporaire
```Bash
az network application-gateway http-listener delete \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name appGatewayHttpListener
```
### Supprimer le HTTP setting temporaire
```Bash
az network application-gateway http-settings delete \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name appGatewayBackendHttpSettings
```
### Supprimer le backend pool temporaire
```Bash
az network application-gateway address-pool delete \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name appGatewayBackendPool
```

## 3. Créer les probes de santé
Les VMSS doivent déjà être associés à leurs pools et leurs services Python doivent être démarrés.
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
    Probe:split(probe.id, '/')[-1]
  }" \
  --output table
```
### résultat
```Bash
Name                           Port    Protocol    Timeout    CookieAffinity    PickHostNameFromBackend    ProbeId
-----------------------------  ------  ----------  ---------  ----------------  -------------------------  --------------------------------------------------------------------------------------------------------------------------------------------------------------
appGatewayBackendHttpSettings  80      Http        30         Disabled          False
http-setting-web               80      Http        30         Disabled          False                      /subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/probes/probe-web
http-setting-api               80      Http        30         Disabled          False                      /subscriptions/088cb8d6-6945-4934-a2cb-cad11b418003/resourceGroups/grp_tpaz104-lab2/providers/Microsoft.Network/applicationGateways/appgw-lab/probes/probe-api
```
<img width="1058" height="190" alt="Capture d&#39;écran 2026-09-10 120812" src="https://github.com/user-attachments/assets/673f7344-1d69-4caf-a156-28c0e2df2a9a" />

## 5. Créer le port HTTP 80
Le port 443 existe déjà. Crée seulement le port 80 :
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
  --query "[].{Name:name,Port:port}" \
  --output table
```
### résultat
```Bash
Name                    Port
----------------------  ----
appGatewayFrontendPort  443
port-80                 80
```
<img width="311" height="98" alt="Capture d&#39;écran 2026-09-10 121028" src="https://github.com/user-attachments/assets/5a52f0ec-1079-4ac5-8644-02bf399fc0f9" />
### Si le port 443 a un autre nom, mettre à jour :
```Bash
PORT_HTTPS_NAME="<NOM_REEL_DU_PORT_443>"
```

## 6. Créer les listeners
Avant de créer le listener HTTPS public, récupèrer le nom réel du certificat :
```Bash
az network application-gateway ssl-cert list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].name" \
  --output table
```
Souvent nommé appgw.pfx, mais vérifiez et stockez-le
```Bash
SSL_CERT_NAME=$(az network application-gateway ssl-cert list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[0].name" \
  --output tsv)

echo "$SSL_CERT_NAME"
```
### Listener public HTTP
```Bash
az network application-gateway http-listener create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PUBLIC_HTTP_LISTENER" \
  --frontend-ip "$PUBLIC_FRONTEND_IP" \
  --frontend-port "$PORT_HTTP_NAME" \
  --protocol Http
```
### Listener public HTTPS
```Bash
az network application-gateway http-listener create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PUBLIC_HTTPS_LISTENER" \
  --frontend-ip "$PUBLIC_FRONTEND_IP" \
  --frontend-port "$PORT_HTTPS_NAME" \
  --protocol Https \
  --ssl-cert "$SSL_CERT_NAME"
```
### Listener privé HTTP
```Bash
az network application-gateway http-listener create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$PRIVATE_HTTP_LISTENER" \
  --frontend-ip "$PRIVATE_FRONTEND_IP" \
  --frontend-port "$PORT_HTTP_NAME" \
  --protocol Http
```
### vérification 
```Bash
az network application-gateway http-listener list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Protocol:protocol,
    FrontendIP:split(frontendIPConfiguration.id, '/')[-1],
    FrontendPort:split(frontendPort.id, '/')[-1],
    SSL:split(sslCertificate.id, '/')[-1]
  }" \
  --output table
```
### résultat
```Bash
A FAIR
```

## 7. Créer la redirection HTTP vers HTTPS
La redirection s’applique uniquement au listener public HTTP/80.
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
### vérification 
```Bash
az network application-gateway redirect-config show \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$REDIRECT_HTTP_TO_HTTPS" \
  --query "{
    Name:name,
    Type:redirectType,
    TargetListener:split(targetListener.id, '/')[-1],
    IncludePath:includePath,
    IncludeQueryString:includeQueryString
  }" \
  --output jsonc
```
### résultat
```Bash
Type               : Permanent
TargetListener     : listener-public-https
IncludePath        : true
IncludeQueryString : true
```
## 8. Créer les URL path maps
Une URL path map a :
    un backend par défaut pour /* : Web ;
    une path rule spécifique /api/* : API.
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
### vérification 
```Bash
for MAP in "$MAP_PUBLIC" "$MAP_PRIVATE"; do
  echo "=== $MAP ==="

  az network application-gateway url-path-map show \
    --resource-group "$RG_WORKLOAD" \
    --gateway-name "$APPGW_NAME" \
    --name "$MAP" \
    --query "{
      DefaultPool:split(defaultBackendAddressPool.id, '/')[-1],
      DefaultSetting:split(defaultBackendHttpSettings.id, '/')[-1],
      PathRules:pathRules[].{
        Name:name,
        Paths:paths,
        Pool:split(backendAddressPool.id, '/')[-1],
        Setting:split(backendHttpSettings.id, '/')[-1]
      }
    }" \
    --output jsonc
done
```
### résultat
```Bash
DefaultPool    : pool-web
DefaultSetting : http-setting-web

PathRules:
  api-route
    /api/*
    pool-api
    http-setting-api
```

## 9.  Créer les règles de routage finales
Les trois priorités sont uniques et lisibles :  
100 → routage HTTPS public  
200 → redirection HTTP public  
300 → routage HTTP privé  
### Règle public HTTPS : PathBasedRouting
```Bash
az network application-gateway rule create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$RULE_PUBLIC_PATH" \
  --rule-type PathBasedRouting \
  --http-listener "$PUBLIC_HTTPS_LISTENER" \
  --url-path-map "$MAP_PUBLIC" \
  --priority 100
```
### Règle public HTTP : redirection 301 vers HTTPS
```Bash
az network application-gateway rule create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$RULE_REDIRECT_HTTP" \
  --rule-type Basic \
  --http-listener "$PUBLIC_HTTP_LISTENER" \
  --redirect-config "$REDIRECT_HTTP_TO_HTTPS" \
  --priority 200
```
### Règle privée HTTP : PathBasedRouting
```Bash
az network application-gateway rule create \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --name "$RULE_PRIVATE_PATH" \
  --rule-type PathBasedRouting \
  --http-listener "$PRIVATE_HTTP_LISTENER" \
  --url-path-map "$MAP_PRIVATE" \
  --priority 300
```

# ✅ Phase 7 — Vérification
```Bash
az network application-gateway rule list \
  --resource-group "$RG_WORKLOAD" \
  --gateway-name "$APPGW_NAME" \
  --query "[].{
    Name:name,
    Priority:priority,
    Type:ruleType,
    Listener:split(httpListener.id, '/')[-1],
    PathMap:split(urlPathMap.id, '/')[-1],
    Redirect:split(redirectConfiguration.id, '/')[-1]
  }" \
  --output table
```
### résultat
```Bash
Name                Priority  Type              Listener               PathMap      Redirect
------------------  --------  ----------------  ---------------------  -----------  ----------------------
rule-public-path    100       PathBasedRouting  listener-public-https  map-public
rule-redirect-http  200       Basic             listener-public-http               redirect-http-to-https
rule-private-path   300       PathBasedRouting  listener-private-http  map-private
```
### Vérification de l’état des backends :
```Bash
az network application-gateway show-backend-health \
  --resource-group "$RG_WORKLOAD" \
  --name "$APPGW_NAME" \
  --output jsonc
```
### résultat
```Bash
pool-web
  → Healthy

pool-api
  → Healthy
```
---

# Phase 8. Tests fonctionnels
## 11. Tests fonctionnels
### Récupérer l’IP publique
```Bash
PUBLIC_IP=$(az network public-ip show \
  --resource-group "$RG_WORKLOAD" \
  --name "$PIP_NAME" \
  --query ipAddress \
  --output tsv)

echo "$PUBLIC_IP"
```
### 11.1 Depuis un PC local en PowerShell
```Bash
curl.exe -k -I "http://<IP_PUBLIQUE>/"
```
### résultat
```Bash
HTTP/1.1 301 Moved Permanently
Location: https://<IP_PUBLIQUE>/
```
### vérification de curl.exe
```Bash
curl.exe -k "https://<IP_PUBLIQUE>/"
curl.exe -k "https://<IP_PUBLIQUE>/api/"
curl.exe -k "https://<IP_PUBLIQUE>/api/health"
```
### résultat
```Bash
OK-WEB
OK-API
OK-API-HEALTHY
```
### 11.2 Depuis la Jumpbox
Via Console Série Azure :
### vérification 
```Bash
curl -i http://10.0.1.10/
curl -i http://10.0.1.10/api/
curl -i http://10.0.1.10/api/health
```
### résultat
```Bash
OK-WEB
OK-API
OK-API-HEALTHY
```

Avant d’activer WAF Prevention :  
passe en Prevention que lorsque tous les tests précédents fonctionnent et que les deux pools sont Healthy.
puis :  
```Bash
az network application-gateway waf-policy policy-setting update \
  --resource-group "$RG_WORKLOAD" \
  --policy-name waf-policy-lab \
  --mode Prevention
```




## 1.
### vérification 
```Bash

```
### résultat
```Bash

```



