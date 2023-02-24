targetScope = 'subscription'
param Location string 
param hubVnetResourceGroupName string

resource hubVnet_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubVnetResourceGroupName
  location: Location
}
