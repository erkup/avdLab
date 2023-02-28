targetScope = 'subscription'

param platformSubscriptionId string
param avdSubscriptionId string 
// -----------------------------------------------------------------
//Resource Group Naming conventions
@description('Name of the resource group for the AD DS VMs')
param dcResourceGroupName string

@description('Name of the resource group for the hub virtual network')
param hubVnetResourceGroupName string

@description('Name of the resource group for the AVD virtual network')
param avdVnetResourceGroupName string

@description('Name of the resource group for AVD resources')
param avdResourceGroupName string

// -----------------------------------------------------------------
@description('Determines the environment of the resource (e.g., \'d\' for Development)')
@allowed (['d','p'])
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

@description('IP address space for AVD virtual network')
param avdVnetAddrPrefix string

// -----------------------------------------------------------------
//On-premises IP Address rangers & VPN configuration settings
@description('IP address space for the on-premises network(s). Can be changed to an array for multiple on-premises networks.')
param onPremVnetAddrPrefix string

@description('Public IP address for the on-premesis VPN device')
param onPremVpnPublicIp string

@description('IPSec VPN pre-shared key')
@secure()
param vpnPresharedKey string

@description('Set username/password for AD DS VMs')
param VmUsername string
@secure()
param VmPassword string

module deployPlatformSubRg './modules/createPlatformSubResources.bicep' = {
  name: 'deployPlatformRg'
  scope: subscription(platformSubscriptionId)
  params: {
    hubVnetResourceGroupName: hubVnetResourceGroupName
    Location: Location
    dcResourceGroupName: dcResourceGroupName
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

module deployAdds './modules/identityFramework.bicep' = {
  name: 'AddsDeployment'
  scope: resourceGroup(platformSubscriptionId,dcResourceGroupName)
  params: {
    hubVnetResourceGroupName: hubVnetResourceGroupName
    platformSubscriptionId: platformSubscriptionId
    Environment: Environment
    Location: Location
    LocationAbbr: LocationAbbr
    VmUsername: VmUsername
    VmPassword: VmPassword
  }
  dependsOn: [
    deployPlatformSubRg
    hubNetworkModule
  ]
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
