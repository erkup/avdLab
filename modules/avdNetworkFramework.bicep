param Environment string 
param Location string
param LocationAbbr string
param hubVnetAddrPrefix string
param avdVnetAddrPrefix string

var HubVnetSubnetPrefix = take(hubVnetAddrPrefix, length(hubVnetAddrPrefix) - 4)
var avdVnetSubnetPrefix = take(avdVnetAddrPrefix, length(hubVnetAddrPrefix) - 4)
var adDcLastOctet = [
  192 + 4
  192 + 5
]
var adDsDnsVmIpAddresses = [
  '${HubVnetSubnetPrefix}${adDcLastOctet[0]}'
  '${HubVnetSubnetPrefix}${adDcLastOctet[1]}'
  '168.63.129.16'
]

resource AVD_SessionHost_network 'Microsoft.Network/virtualNetworks@2022-07-01' = {
  name: 'AVD-${Environment}-${LocationAbbr}-vnet'
  location: Location
  tags: {
  }
  properties: {
    addressSpace: {
      addressPrefixes: [
        avdVnetAddrPrefix
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
        name: 'avdSessionHost-Subnet'
        properties: {
          addressPrefix: '${avdVnetSubnetPrefix}0/26'
          privateEndpointNetworkPolicies: 'Enabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
    ]
  }
}
output AVD_SessionHost_network  object = {
  name: AVD_SessionHost_network.name
  id: AVD_SessionHost_network.id
  dnsServers: AVD_SessionHost_network.properties.dhcpOptions.dnsServers
}
