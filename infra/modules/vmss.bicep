// modules/vmss.bicep
// VMSS Web + API avec cloud-init, sans autoscale

param location string = 'westeurope'
param subnetBackendAId string
param subnetBackendBId string
param poolWebId string
param poolApiId string

// Noms fixes
param vmssWebName string = 'vmss-web'
param vmssApiName string = 'vmss-api'

// Paramètres utilisateur
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

// VMSS Web
resource vmssWeb 'Microsoft.Compute/virtualMachineScaleSets@2026-03-01' = {
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
        imageReference: {
          publisher: imagePublisher
          offer: imageOffer
          sku: imageSku
          version: imageVersion
        }
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
                      id: subnetBackendAId
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

// VMSS API
resource vmssApi 'Microsoft.Compute/virtualMachineScaleSets@2026-03-01' = {
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
        imageReference: {
          publisher: imagePublisher
          offer: imageOffer
          sku: imageSku
          version: imageVersion
        }
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
                      id: subnetBackendBId
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

// Outputs
output vmssWebId string = vmssWeb.id
output vmssApiId string = vmssApi.id
