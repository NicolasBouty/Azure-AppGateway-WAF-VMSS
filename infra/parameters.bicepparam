// parameters.bicepparam
// Paramètres principaux du déploiement

using './main.bicep'

resourceGroupName: 'rg-az104-lab'
location: 'westeurope'

adminUsername: 'azureuser'
adminPassword: readEnvironmentVariable('AZURE_ADMIN_PASSWORD')

vmSku: 'Standard_D2als_v7'
jumpboxSku: 'Standard_D2als_v7'

imagePublisher: 'Canonical'
imageOffer: 'ubuntu-24_04-lts'
imageSku: 'server'
imageVersion: 'latest'

sslCertificatePassword: readEnvironmentVariable('PFX_PASSWORD')
sslCertificateData: readEnvironmentVariable('PFX_DATA_B64')
