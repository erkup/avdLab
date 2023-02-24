param HubVnet object
param AVD_SessionHost_network object

resource hubPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${HubVnet.name}/${HubVnet.name}-peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: AVD_SessionHost_network.id
    }
  }
}

resource AVD_SessionHost_networkPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${AVD_SessionHost_network.name}/${AVD_SessionHost_network.name}-peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: HubVnet.id
    }
  }
}
