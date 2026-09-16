// modules/network.bicep
// VNet, subnets et NSG avec toutes les règles du lab

param location string = 'westeurope'

// Noms des ressources (fixes)
param vnetName string = 'vnet_tpaz104-lab'
param nsgAppgwName string = 'nsg-appgw'
param nsgBackendAName string = 'nsg-backend-a'
param nsgBackendBName string = 'nsg-backend-b'
param nsgMgmtName string = 'nsg-mgmt'

// Plages d'adressage (fixes)
param vnetAddressPrefix string = '10.0.0.0/16'
param subnetAppgwPrefix string = '10.0.1.0/24'
param subnetBackendAPrefix string = '10.0.2.0/24'
param subnetBackendBPrefix string = '10.0.3.0/24'
param subnetMgmtPrefix string = '10.0.4.0/24'

// NSG AppGW
resource nsgAppgw 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgAppgwName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-Internet-To-Public-Listeners'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          destinationPortRanges: [
            '80'
            '443'
          ]
        }
      }
      {
        name: 'Allow-Mgmt-To-Private-Listener-8080'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.1.10'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-GatewayManager-Inbound'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '65200-65535'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 120
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-AzureLoadBalancer-Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 130
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-VNet-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow-Internet-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
    ]
  }
}

// NSG Backend A (Web)
resource nsgBackendA 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgBackendAName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-From-AppGW'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '10.0.2.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-From-Jumpbox'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.2.0/24'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-Test-Port-8080'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.2.0/24'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

// NSG Backend B (API)
resource nsgBackendB 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgBackendBName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Allow-HTTP-From-AppGW'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '10.0.1.0/24'
          destinationAddressPrefix: '10.0.3.0/24'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-From-Jumpbox'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.3.0/24'
          access: 'Allow'
          priority: 110
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-Test-Port-8080'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.3.0/24'
          access: 'Deny'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'Deny-All-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

// NSG Management (Jumpbox)
resource nsgMgmt 'Microsoft.Network/networkSecurityGroups@2025-07-01' = {
  name: nsgMgmtName
  location: location
  properties: {
    securityRules: [
      {
        name: 'Deny-All-Inbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
        }
      }
      {
        name: 'Allow-SSH-To-Backends'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefixes: [
            '10.0.2.0/24'
            '10.0.3.0/24'
          ]
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
        }
      }
      {
        name: 'Allow-8080-To-AppGW-PrivateFrontend'
        properties: {
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8080'
          sourceAddressPrefix: '10.0.4.0/24'
          destinationAddressPrefix: '10.0.1.10'
          access: 'Allow'
          priority: 110
          direction: 'Outbound'
        }
      }
      {
        name: 'Deny-All-Outbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Outbound'
        }
      }
    ]
  }
}

// VNet
resource vnet 'Microsoft.Network/virtualNetworks@2025-07-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      {
        name: 'subnet-appgw'
        properties: {
          addressPrefix: subnetAppgwPrefix
          networkSecurityGroup: {
            id: nsgAppgw.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'subnet-backend-a'
        properties: {
          addressPrefix: subnetBackendAPrefix
          networkSecurityGroup: {
            id: nsgBackendA.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'subnet-backend-b'
        properties: {
          addressPrefix: subnetBackendBPrefix
          networkSecurityGroup: {
            id: nsgBackendB.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'subnet-mgmt'
        properties: {
          addressPrefix: subnetMgmtPrefix
          networkSecurityGroup: {
            id: nsgMgmt.id
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}

// Outputs pour les autres modules
output vnetId string = vnet.id
output subnetAppgwId string = '${vnet.id}/subnets/subnet-appgw'
output subnetBackendAId string = '${vnet.id}/subnets/subnet-backend-a'
output subnetBackendBId string = '${vnet.id}/subnets/subnet-backend-b'
output subnetMgmtId string = '${vnet.id}/subnets/subnet-mgmt'
output nsgAppgwId string = nsgAppgw.id
output nsgBackendAId string = nsgBackendA.id
output nsgBackendBId string = nsgBackendB.id
output nsgMgmtId string = nsgMgmt.id
