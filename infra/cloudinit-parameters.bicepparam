// cloudinit-parameters.bicepparam
// Paramètres cloud-init pour VMSS Web et API

using './main.bicep'

param customDataWeb = readEnvironmentVariable('CLOUD_INIT_WEB_B64')
param customDataApi = readEnvironmentVariable('CLOUD_INIT_API_B64')
