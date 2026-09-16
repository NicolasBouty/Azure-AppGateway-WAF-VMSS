// parameters.bicepparam
// Paramètres principaux du déploiement

using './main.bicep'

param resourceGroupName = 'rg-az104-lab'
param location = 'westeurope'

// Identifiants communs VMSS + Jumpbox
param adminUsername = 'azureuser'
param adminPassword = readEnvironmentVariable('AZURE_ADMIN_PASSWORD')

// SKU des VM
param vmSku = 'Standard_D2als_v7'
param jumpboxSku = 'Standard_D2als_v7'

// Image Ubuntu 24.04 LTS
param imagePublisher = 'Canonical'
param imageOffer = 'ubuntu-24_04-lts'
param imageSku = 'server'
param imageVersion = 'latest'

// Certificat PFX
param sslCertificatePassword = readEnvironmentVariable('PFX_PASSWORD')
param sslCertificateData = readEnvironmentVariable('PFX_DATA_B64')
