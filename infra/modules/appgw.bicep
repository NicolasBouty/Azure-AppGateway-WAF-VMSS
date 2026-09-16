// modules/appgw.bicep
// Application Gateway v2 WAF + PIP + WAF Policy + certificat PFX

param location string = 'westeurope'
param subnetAppgwId string

// Noms fixes
param appgwName string = 'appgw-lab'
param pipName string = 'pip-appgw'
param wafPolicyName string = 'waf-policy-lab'
param sslCertName string = 'appgw-labSslCert'

// Paramètres utilisateur
@secure()
param sslCertificateData string
@secure()
param sslCertificatePassword string

// IP publique
resource pip 'Microsoft.Network/publicIPAddresses@2025-07-01' = {
  name: pipName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

// WAF Policy
resource wafPolicy 'Microsoft.Network/ApplicationGatewayWebApplicationFirewallPolicies@2025-07-01' = {
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

// Application Gateway
resource appgw 'Microsoft.Network/applicationGateways@2025-07-01' = {
  name: appgwName
  location: location
  sku: {
    name: 'WAF_v2'
    tier: 'WAF_v2'
    capacity: 2
  }
  properties: {
    gatewayIPConfigurations: [
      {
        name: 'gateway-ip-config'
        properties: {
          subnet: {
            id: subnetAppgwId
          }
        }
      }
    ]
    frontendIPConfigurations: [
      {
        name: 'public-frontend-ip'
        properties: {
          publicIPAddress: {
            id: pip.id
          }
        }
      }
      {
        name: 'private-frontend-ip'
        properties: {
          privateIPAddress: '10.0.1.10'
          privateIPAllocationMethod: 'Static'
          subnet: {
            id: subnetAppgwId
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
        name: sslCertName
        properties: {
          data: sslCertificateData
          password: sslCertificatePassword
        }
      }
    ]
    backendAddressPools: [
      {
        name: 'pool-web'
      }
      {
        name: 'pool-api'
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
            id: '${appgw.id}/probes/probe-web'
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
            id: '${appgw.id}/probes/probe-api'
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
            id: '${appgw.id}/frontendIPConfigurations/public-frontend-ip'
          }
          frontendPort: {
            id: '${appgw.id}/frontendPorts/port-80'
          }
        }
      }
      {
        name: 'listener-public-https'
        properties: {
          protocol: 'Https'
          frontendIPConfiguration: {
            id: '${appgw.id}/frontendIPConfigurations/public-frontend-ip'
          }
          frontendPort: {
            id: '${appgw.id}/frontendPorts/port-443'
          }
          sslCertificate: {
            id: '${appgw.id}/sslCertificates/${sslCertName}'
          }
        }
      }
      {
        name: 'listener-private-http'
        properties: {
          protocol: 'Http'
          frontendIPConfiguration: {
            id: '${appgw.id}/frontendIPConfigurations/private-frontend-ip'
          }
          frontendPort: {
            id: '${appgw.id}/frontendPorts/port-8080'
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
            id: '${appgw.id}/httpListeners/listener-public-https'
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
            id: '${appgw.id}/backendAddressPools/pool-web'
          }
          defaultBackendHttpSettings: {
            id: '${appgw.id}/backendHttpSettingsCollection/http-setting-web'
          }
          pathRules: [
            {
              name: 'api-route'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: '${appgw.id}/backendAddressPools/pool-api'
                }
                backendHttpSettings: {
                  id: '${appgw.id}/backendHttpSettingsCollection/http-setting-api'
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
            id: '${appgw.id}/backendAddressPools/pool-web'
          }
          defaultBackendHttpSettings: {
            id: '${appgw.id}/backendHttpSettingsCollection/http-setting-web'
          }
          pathRules: [
            {
              name: 'api-route'
              properties: {
                paths: [
                  '/api/*'
                ]
                backendAddressPool: {
                  id: '${appgw.id}/backendAddressPools/pool-api'
                }
                backendHttpSettings: {
                  id: '${appgw.id}/backendHttpSettingsCollection/http-setting-api'
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
            id: '${appgw.id}/httpListeners/listener-public-https'
          }
          urlPathMap: {
            id: '${appgw.id}/urlPathMaps/map-public'
          }
        }
      }
      {
        name: 'rule-redirect-http'
        properties: {
          ruleType: 'Basic'
          priority: 200
          httpListener: {
            id: '${appgw.id}/httpListeners/listener-public-http'
          }
          redirectConfiguration: {
            id: '${appgw.id}/redirectConfigurations/redirect-http-to-https'
          }
        }
      }
      {
        name: 'rule-private-path'
        properties: {
          ruleType: 'PathBasedRouting'
          priority: 300
          httpListener: {
            id: '${appgw.id}/httpListeners/listener-private-http'
          }
          urlPathMap: {
            id: '${appgw.id}/urlPathMaps/map-private'
          }
        }
      }
    ]
    firewallPolicy: {
      id: wafPolicy.id
    }
  }
}

// Outputs
output appgwId string = appgw.id
output pipId string = pip.id
output wafPolicyId string = wafPolicy.id
output poolWebId string = '${appgw.id}/backendAddressPools/pool-web'
output poolApiId string = '${appgw.id}/backendAddressPools/pool-api'
