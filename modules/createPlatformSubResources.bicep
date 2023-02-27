targetScope = 'subscription'
param Location string 
param hubVnetResourceGroupName string
param dcResourceGroupName string

resource hubVnet_rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: hubVnetResourceGroupName
  location: Location
}

resource createAdsRg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: dcResourceGroupName
  location: Location
}
