// main.bicep
// Orchestrateur principal qui appelle les modules

param location string = 'westeurope'

// Paramètres réseau (noms et plages fixes)
param vnetName string = 'vnet_tpaz104-lab'
param nsgAppgwName string = 'nsg-appgw'
param nsgBackendAName string = 'nsg-backend-a'
param nsgBackendBName string = 'nsg-backend-b'
param nsgMgmtName string = 'nsg-mgmt'

// Paramètres AppGW
param appgwName string = 'appgw-lab'
param pipName string = 'pip-appgw'
param wafPolicyName string = 'waf-policy-lab'
@secure()
param sslCertificateData string
@secure()
param sslCertificatePassword string

// Paramètres VMSS
param vmssWebName string = 'vmss-web'
param vmssApiName string = 'vmss-api'
param adminUsername string
@secure()
param adminPassword string
param vmSku string
param imagePublisher string
param imageOffer string
param imageSku string
param imageVersion string
@secure()
param customDataWeb string
@secure()
param customDataApi string

// Paramètres Jumpbox
param jumpboxName string = 'vm-jumpbox'
param jumpboxSku string

// Module Réseau
module network 'modules/network.bicep' = {
  name: 'network'
  params: {
    location: location
    vnetName: vnetName
    nsgAppgwName: nsgAppgwName
    nsgBackendAName: nsgBackendAName
    nsgBackendBName: nsgBackendBName
    nsgMgmtName: nsgMgmtName
  }
}

// Module Application Gateway
module appgw 'modules/appgw.bicep' = {
  name: 'appgw'
  params: {
    location: location
    subnetAppgwId: network.outputs.subnetAppgwId
    sslCertificateData: sslCertificateData
    sslCertificatePassword: sslCertificatePassword
  }
}

// Module VMSS
module vmss 'modules/vmss.bicep' = {
  name: 'vmss'
  params: {
    location: location
    subnetBackendAId: network.outputs.subnetBackendAId
    subnetBackendBId: network.outputs.subnetBackendBId
    poolWebId: appgw.outputs.poolWebId
    poolApiId: appgw.outputs.poolApiId
    adminUsername: adminUsername
    adminPassword: adminPassword
    vmSku: vmSku
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSku: imageSku
    imageVersion: imageVersion
    customDataWeb: customDataWeb
    customDataApi: customDataApi
  }
}

// Module Jumpbox
module jumpbox 'modules/jumpbox.bicep' = {
  name: 'jumpbox'
  params: {
    location: location
    subnetMgmtId: network.outputs.subnetMgmtId
    adminUsername: adminUsername
    adminPassword: adminPassword
    jumpboxSku: jumpboxSku
    imagePublisher: imagePublisher
    imageOffer: imageOffer
    imageSku: imageSku
    imageVersion: imageVersion
  }
}

// Outputs globaux
output vnetId string = network.outputs.vnetId
output appgwPublicIpId string = appgw.outputs.pipId
output appgwId string = appgw.outputs.appgwId
