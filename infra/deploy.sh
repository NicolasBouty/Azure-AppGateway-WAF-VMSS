#!/usr/bin/env bash
set -euo pipefail

# ============================
# 1. Création du Resource Group
# ============================
az group create \
  --name rg-az104-lab \
  --location westeurope


# ============================
# 2. Encodage du certificat PFX
# ============================
if [ ! -f ~/appgw.pfx ]; then
  echo "Erreur : fichier ~/appgw.pfx introuvable."
  exit 1
fi

export PFX_DATA_B64=$(base64 ~/appgw.pfx | tr -d '\r\n')

read -rsp "Mot de passe du certificat PFX : " PFX_PASSWORD
echo
export PFX_PASSWORD


# ============================
# 3. Encodage des fichiers cloud-init
# ============================
for FILE in cloud-init-web.yaml cloud-init-api.yaml; do
  if [ ! -f "$FILE" ]; then
    echo "Erreur : fichier $FILE introuvable."
    exit 1
  fi
done

export CLOUD_INIT_WEB_B64=$(base64 -w 0 cloud-init-web.yaml)
export CLOUD_INIT_API_B64=$(base64 -w 0 cloud-init-api.yaml)


# ============================
# 4. Mot de passe admin VMSS + Jumpbox
# ============================
read -rsp "Mot de passe admin pour VMSS et Jumpbox : " AZURE_ADMIN_PASSWORD
echo
export AZURE_ADMIN_PASSWORD


# ============================
# 5. Déploiement Bicep
# ============================
az deployment group create \
  --resource-group rg-az104-lab \
  --template-file main.bicep \
  --parameters parameters.bicepparam cloudinit-parameters.bicepparam


echo "Déploiement terminé avec succès."

# IMPORTANT :
# rendre exécutable avec : chmod +x deploy.sh
