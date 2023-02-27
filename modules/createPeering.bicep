param sourceVnet object
param destinationVnet object
param remoteVnetRg string
param remoteVnetSubscription string

resource vnetPeering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2020-07-01' = {
  name: '${sourceVnet.name}/${sourceVnet.name}2${destinationVnet.name}-peering'
  properties: {
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
    allowGatewayTransit: true
    useRemoteGateways: false
    remoteVirtualNetwork: {
      id: resourceId(remoteVnetSubscription, remoteVnetRg, 'Microsoft.Network/virtualNetworks', destinationVnet.name)
    }
  }
}
