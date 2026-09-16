// modules/jumpbox.bicep
// VM Jumpbox privée sans IP publique

param location string = 'westeurope'
param subnetMgmtId string

// Noms fixes
param jumpboxName string = 'vm-jumpbox'

// Paramètres utilisateur
param adminUsername string
@secure()
param adminPassword string
param jumpboxSku string
param imagePublisher string
param imageOffer string
param imageSku string
param imageVersion string

// NIC (créé implicitement par az vm create, mais on le déclare ici pour être explicite)
resource nic 'Microsoft.Network/networkInterfaces@2025-07-01' = {
  name: '${jumpboxName}VMNic'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfigvm-jumpbox'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetMgmtId
          }
        }
      }
    ]
    enableIPForwarding: false
  }
}

// VM Jumpbox
resource jumpbox 'Microsoft.Compute/virtualMachines@2026-03-01' = {
  name: jumpboxName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: jumpboxSku
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
          storageAccountType: 'Premium_LRS'
        }
        diskSizeGB: 30
      }
    }
    osProfile: {
      computerName: jumpboxName
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
        provisionVMAgent: true
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
      }
    }
  }
}

// Outputs
output jumpboxId string = jumpbox.id
output jumpboxNicId string = nic.id
