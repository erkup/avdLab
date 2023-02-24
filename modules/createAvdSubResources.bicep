targetScope = 'subscription'
param Location string

@description('Name of the resource group for the AVD virtual network')
param avdVnetResourceGroupName string

@description('Name of the resource group for AVD resources')
param avdResourceGroupName string

resource avdVnet_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdVnetResourceGroupName
  location: Location
}
resource avd_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: avdResourceGroupName
  location: Location
}
