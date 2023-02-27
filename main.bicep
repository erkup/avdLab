targetScope = 'subscription'

param platformSubscriptionId string = subscription().subscriptionId
param avdSubscriptionId string 
// -----------------------------------------------------------------
//Resource Group Naming conventions
@description('Name of the resource group for the hub virtual network')
param hubVnetResourceGroupName string = 'hub-network-rg'

@description('Name of the resource group for the AVD virtual network')
param avdVnetResourceGroupName string = 'avd-network-rg'

@description('Name of the resource group for AVD resources')
param avdResourceGroupName string = 'avd-rg'

// -----------------------------------------------------------------
@description('Determines the environment of the resource (e.g., \'d\' for Development)')
@allowed (['d','p'])
param Environment string = 'p'

// -----------------------------------------------------------------
// location for deploying resources & resource naming conventions
@description('Location is used to specify the deployment location for each Resource')
param Location string = 'eastus'

@description('Location Abbreviation is used to name Resources')
param LocationAbbr string = 'eus'

// Azure IP Address space for the hub virtual networks
@description('IP address space for AVD virtual network')
param hubVnetAddrPrefix string = '10.0.0.0/21'

@description('IP address space for AVD virtual network')
param avdVnetAddrPrefix string = '10.3.0.0/21'

// -----------------------------------------------------------------
//On-premises IP Address rangers & VPN configuration settings
@description('IP address space for the on-premises network(s). Can be changed to an array for multiple on-premises networks.')
param onPremVnetAddrPrefix string

@description('Public IP address for the on-premesis VPN device')
param onPremVpnPublicIp string

@description('IPSec VPN pre-shared key')
@secure()
param vpnPresharedKey string

module deployPlatformSubRg './modules/createPlatformSubResources.bicep' = {
  name: 'deployPlatformRg'
  scope: subscription(platformSubscriptionId)
  params: {
    hubVnetResourceGroupName: hubVnetResourceGroupName
    Location: Location
  }
}

module deployAvdSubRg './modules/createAvdSubResources.bicep' = {
  name: 'deployAvdSubRg'
  scope: subscription(avdSubscriptionId)
  params: {
    avdVnetResourceGroupName: avdVnetResourceGroupName
    avdResourceGroupName: avdResourceGroupName
    Location: Location
  }
}

module hubNetworkModule './modules/hubNetworkFramework.bicep' = {
  name: 'networkDeploy'
  scope: resourceGroup(platformSubscriptionId,hubVnetResourceGroupName)
  dependsOn: [
    deployPlatformSubRg
  ]
  params: {
    Environment: Environment
    Location: Location
    LocationAbbr: LocationAbbr
    hubVnetAddrPrefix: hubVnetAddrPrefix
    onPremVnetAddrPrefix: onPremVnetAddrPrefix
    onPremVpnPublicIp: onPremVpnPublicIp
    vpnPresharedKey: vpnPresharedKey
  }
}

module avdNetworkModule './modules/avdNetworkFramework.bicep' = {
  name: 'avdNetworkDeploy'
  scope: resourceGroup(avdSubscriptionId,avdVnetResourceGroupName)
  dependsOn: [
    deployAvdSubRg
  ]
  params: {
    Environment: Environment
    Location: Location
    LocationAbbr: LocationAbbr
    hubVnetAddrPrefix: hubVnetAddrPrefix
    avdVnetAddrPrefix: avdVnetAddrPrefix
  }
}

module createHubPeering './modules/createPeering.bicep' = {
  name: 'create1Peering'
  scope: resourceGroup(platformSubscriptionId,hubVnetResourceGroupName)
  params: {
    sourceVnet: hubNetworkModule.outputs.hubVnet
    destinationVnet: avdNetworkModule.outputs.AVD_SessionHost_network
    remoteVnetRg: avdVnetResourceGroupName
    remoteVnetSubscription: avdSubscriptionId
    }
}

module createAvdPeering './modules/createPeering.bicep' = {
  name: 'create2Peering'
  scope: resourceGroup(avdSubscriptionId,avdVnetResourceGroupName)
  params: {
    sourceVnet: avdNetworkModule.outputs.AVD_SessionHost_network
    destinationVnet: hubNetworkModule.outputs.hubVnet
    remoteVnetRg: hubVnetResourceGroupName
    remoteVnetSubscription: platformSubscriptionId
    }
}
