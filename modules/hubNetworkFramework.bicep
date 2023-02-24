@description('Determines the environment of the resource (e.g., \'d\' for Development)')
@allowed([ 'd', 'p' ])
param Environment string

// -----------------------------------------------------------------
// location for deploying resources & resource naming conventions
@description('Location is used to specify the deployment location for each Resource')
param Location string

@description('Location Abbreviation is used to name Resources')
param LocationAbbr string

// Azure IP Address space for the hub virtual networks
@description('IP address space for AVD virtual network')
param hubVnetAddrPrefix string

// -----------------------------------------------------------------
//On-premises IP Address rangers & VPN configuration settings
@description('IP address space for the on-premises network(s). Can be changed to an array for multiple on-premises networks.')
param onPremVnetAddrPrefix string

@description('Public IP address for the on-premesis VPN device')
param onPremVpnPublicIp string

@description('IPSec VPN pre-shared key')
@secure()
param vpnPresharedKey string

var HubVnetSubnetPrefix = take(hubVnetAddrPrefix, length(hubVnetAddrPrefix) - 4)
var adDcLastOctet = [
  192 + 4
  192 + 5
]
var adDsDnsVmIpAddresses = [
  '${HubVnetSubnetPrefix}${adDcLastOctet[0]}'
  '${HubVnetSubnetPrefix}${adDcLastOctet[1]}'
  '168.63.129.16'
]
var NsgBastionName = 'nsg-bastion-${Environment}-${LocationAbbr}'
var NsgIdName = 'nsg-identity-${Environment}-${LocationAbbr}'
resource NsgId 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: NsgIdName
  location: Location
  properties: {
    securityRules: [
      {
        name: 'AllowDomainControllerTcpInbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
          destinationPortRanges: [
            '53'
            '88'
            '135'
            '389'
            '445'
            '464'
            '636'
            '3268'
            '3269'
            '4500'
            '9389'
            '49152-65535'
          ]
          destinationAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
        }
      }
      {
        name: 'AllowDomainControllerUdpInbound'
        properties: {
          protocol: 'UDP'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
          destinationPortRanges: [
            '53'
            '88'
            '123'
            '389'
            '464'
            '500'
            '4500'
          ]
          destinationAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
        }
      }
      {
        name: 'AllowBastionInbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '3389'
          sourceAddressPrefix: '10.0.0.128/26'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowWinrmInbound'
        properties: {
          description: 'WinRM'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '5986'
          sourceAddressPrefix: adDsDnsVmIpAddresses[1]
          destinationAddressPrefix: adDsDnsVmIpAddresses[0]
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowIcmpInbound'
        properties: {
          protocol: 'ICMP'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 500
          direction: 'Inbound'
        }
      }
      {
        name: 'DenyAllInbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Deny'
          priority: 4096
          direction: 'Inbound'
          sourcePortRanges: []
          destinationPortRanges: []
          sourceAddressPrefixes: []
          destinationAddressPrefixes: []
        }
      }
      {
        name: 'AllowDomainControllerTcpOutbound'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          destinationPortRanges: [
            '53'
            '88'
            '135'
            '389'
            '445'
            '464'
            '636'
            '3268'
            '3269'
            '4500'
            '9389'
            '49152-65535'
          ]
          sourceAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
          destinationAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
        }
      }
      {
        name: 'AllowDomainControllerUdpOutbound'
        properties: {
          protocol: 'UDP'
          sourcePortRange: '*'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
          destinationPortRanges: [
            '53'
            '88'
            '123'
            '389'
            '464'
            '500'
            '4500'
          ]
          sourceAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
          destinationAddressPrefixes: [
            adDsDnsVmIpAddresses[0]
            adDsDnsVmIpAddresses[1]
          ]
        }
      }
      {
        name: 'AllowWinrmOutbound'
        properties: {
          description: 'WinRM'
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '5986'
          sourceAddressPrefix: adDsDnsVmIpAddresses[1]
          destinationAddressPrefix: adDsDnsVmIpAddresses[0]
          access: 'Allow'
          priority: 300
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowInternetOutbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 400
          direction: 'Outbound'
          destinationPortRanges: [
            '443'
            '80'
          ]
          sourceAddressPrefixes: [
            '10.0.0.196'
            '10.0.0.197'
          ]
        }
      }
      {
        name: 'AllowSmbOutbound'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '445'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 500
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllOutbound'
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

resource NsgBastion 'Microsoft.Network/networkSecurityGroups@2020-05-01' = {
  name: NsgBastionName
  location: Location
  properties: {
    securityRules: [
      {
        name: 'AllowBastionClients'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'Internet'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 100
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowGatewayManager'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'GatewayManager'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 200
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowAzureLoadBalancer'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: 'AzureLoadBalancer'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 300
          direction: 'Inbound'
        }
      }
      {
        name: 'AllowBastionHostCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 400
          direction: 'Inbound'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowSshRdp'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 100
          direction: 'Outbound'
          destinationPortRanges: [
            '22'
            '3389'
          ]
        }
      }
      {
        name: 'AllowAzureCloud'
        properties: {
          protocol: 'TCP'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'AzureCloud'
          access: 'Allow'
          priority: 200
          direction: 'Outbound'
        }
      }
      {
        name: 'AllowBastionCommunication'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
          access: 'Allow'
          priority: 300
          direction: 'Outbound'
          destinationPortRanges: [
            '8080'
            '5701'
          ]
        }
      }
      {
        name: 'AllowGetSessionInformation'
        properties: {
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: 'Internet'
          access: 'Allow'
          priority: 400
          direction: 'Outbound'
        }
      }
      {
        name: 'DenyAllInbound'
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
        name: 'DenyAllOutbound'
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

resource HubVnet 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'Hub-${Environment}-${LocationAbbr}-vnet'
  location: Location
  tags: {
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddrPrefix
      ]
    }
    dhcpOptions: {
      dnsServers: [
        adDsDnsVmIpAddresses[0]
        adDsDnsVmIpAddresses[1]
        adDsDnsVmIpAddresses[2]
      ]
    }
    subnets: [
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '${HubVnetSubnetPrefix}0/26'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureFirewallSubnet'
        properties: {
          addressPrefix: '${HubVnetSubnetPrefix}64/26'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'AzureBastionSubnet'
        properties: {
          addressPrefix: '${HubVnetSubnetPrefix}128/26'
          networkSecurityGroup: {
            id: NsgBastion.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'identity${Environment}-${LocationAbbr}-subnet'
        properties: {
          addressPrefix: '${HubVnetSubnetPrefix}192/26'
          networkSecurityGroup: {
            id: NsgId.id
          }
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
    enableDdosProtection: false
    enableVmProtection: false
  }
}

resource bastion_pip 'Microsoft.Network/publicIPAddresses@2020-05-01' = {
  name: 'pip-bastion-${Environment}-${LocationAbbr}'
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

resource bastion_host 'Microsoft.Network/bastionHosts@2020-05-01' = {
  name: 'bastion-${Environment}-${LocationAbbr}'
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'IpConf'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: bastion_pip.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Hub-${Environment}-${LocationAbbr}-vnet', 'AzureBastionSubnet')
          }
        }
      }
    ]
  }
  dependsOn: [

    HubVnet
  ]
}

resource vpnGw_pip 'Microsoft.Network/publicIPAddresses@2022-07-01' = {
  name: 'pip-vpn-${Environment}-${LocationAbbr}'
  location: Location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Virtual Network Gateway - the Azure resource that terminates the VPN connection
resource vpnGw 'Microsoft.Network/virtualNetworkGateways@2020-11-01' = {
  name: '${Environment}-${LocationAbbr}-vpnGw'
  location: Location
  properties: {
    ipConfigurations: [
      {
        name: 'vpnGwIpConfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'Hub-${Environment}-${LocationAbbr}-vnet', 'GatewaySubnet')
          }
          publicIPAddress: {
            id: vpnGw_pip.id
          }
        }
      }
    ]
    sku: {
      name: 'VpnGw2'
      tier: 'VpnGw2'
    }
    gatewayType: 'Vpn'
    vpnType: 'RouteBased'
    enableBgp: false
  }
}
// Local Network Gateway - repreresents the on-premises VPN location address space
resource vpn_LNG 'Microsoft.Network/localNetworkGateways@2019-11-01' = {
  name: 'OnPremDc-${Environment}-${LocationAbbr}-LNG'
  location: Location
  properties: {
    localNetworkAddressSpace: {
      addressPrefixes: [
        onPremVnetAddrPrefix
      ]
    }
    gatewayIpAddress: onPremVpnPublicIp
  }
}

// Virtual Network Gateway Connection - the connection between the Azure VPN Gateway and the on-premises VPN Gateway
resource vpnGw_conn 'Microsoft.Network/connections@2022-07-01' = {
  name: '${Environment}-${LocationAbbr}-vpnGw-conn'
  location: Location
  properties: {
    #disable-next-line BCP035
    virtualNetworkGateway1: {
      id: vpnGw.id
    }
    #disable-next-line BCP035
    localNetworkGateway2: {
      id: vpn_LNG.id
    }
    connectionType: 'IPsec'
    enableBgp: false
    sharedKey: vpnPresharedKey
  }
}

output hubVnet object = {
  name: HubVnet.name
  id: HubVnet.id
  dnsServers: HubVnet.properties.dhcpOptions.dnsServers
}
