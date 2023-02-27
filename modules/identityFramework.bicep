param hubVnetResourceGroupName string
param platformSubscriptionId string
// param Domain string
@description('Determines the environment of the resource (e.g., \'d\' for Development)')
@allowed (['d','p'])
param Environment string
// -----------------------------------------------------------------
// location for deploying resources & resource naming conventions
@description('Location is used to specify the deployment location for each Resource')
param Location string

@description('Location Abbreviation is used to name Resources')
param LocationAbbr string

/* param IpAddresses array = [

] */
@secure()
param VmPassword string
param VmUsername string

resource dc_availabilitySet 'Microsoft.Compute/availabilitySets@2019-07-01' = {
  name: '${Environment}-${LocationAbbr}-dc-as'
  location: Location
  properties: {
    platformFaultDomainCount: 2
    platformUpdateDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}

resource dc_nics 'Microsoft.Network/networkInterfaces@2018-08-01' = [for i in range(0, 2): {
  name: 'vm-dc-${LocationAbbr}-${i}-nic'
  location: Location
  tags: {
  }
  properties: {
    ipConfigurations: [
      {
        name: 'ipConfig0'
        properties: {
/*           privateIPAllocationMethod: 'Static'
          privateIPAddress: IpAddresses[i] */
          subnet: {
            id: resourceId(platformSubscriptionId, hubVnetResourceGroupName, 'Microsoft.Network/virtualNetworks/subnets', 'Hub-${Environment}-${LocationAbbr}-vnet', 'identity${Environment}-${LocationAbbr}-subnet')
          }
        }
      }
    ]
  }
  dependsOn: []
}]

resource dc_Vm 'Microsoft.Compute/virtualMachines@2019-07-01' = [for i in range(0, 2): {
  name: 'vm-dc-${LocationAbbr}-${i}'
  location: Location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B2s'
    }
    osProfile: {
      computerName: 'vm-dc-${LocationAbbr}-${i}'
      adminUsername: VmUsername
      adminPassword: VmPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: '2019-Datacenter'
        version: 'latest'
      }
      osDisk: {
        name: 'vm-dc-${LocationAbbr}-${i}-osdisk'
        caching: 'None'
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: resourceId('Microsoft.Network/networkInterfaces', 'vm-dc-${LocationAbbr}-${i}-nic')
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: false
      }
    }
    availabilitySet: {
      id: dc_availabilitySet.id
    }
  }
  dependsOn: [
    dc_nics
  ]
}]

/* resource vm_dc_Environment_LocationAbbr_0_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: 'vm-dc-${Environment}-${LocationAbbr}-0/DSC'
  location: Location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    protectedSettings: {
      Items: {
        VmPassword: VmPassword
      }
    }
    settings: {
      wmfVersion: 'latest'
      modulesUrl: 'https://github.com/microsoft/WhatTheHack/blob/master/037-AzureVirtualDesktop/Student/Resources/dsc/ActiveDirectoryForest.zip?raw=true'
      configurationFunction: 'ActiveDirectoryForest.ps1\\ActiveDirectoryForest'
      properties: {
        Domain: Domain
        DomainCreds: {
          UserName: VmUsername
          Password: 'PrivateSettingsRef:VmPassword'
        }
      }
    }
  }
  dependsOn: [
    dc_Vm
  ]
}

resource vm_dc_Environment_LocationAbbr_1_DSC 'Microsoft.Compute/virtualMachines/extensions@2019-07-01' = {
  name: 'vm-dc-${Environment}-${LocationAbbr}-1/DSC'
  location: Location
  properties: {
    publisher: 'Microsoft.Powershell'
    type: 'DSC'
    typeHandlerVersion: '2.77'
    autoUpgradeMinorVersion: true
    forceUpdateTag: Timestamp
    protectedSettings: {
      Items: {
        VmPassword: VmPassword
      }
    }
    settings: {
      wmfVersion: 'latest'
      modulesUrl: 'https://github.com/microsoft/WhatTheHack/blob/master/037-AzureVirtualDesktop/Student/Resources/dsc/ActiveDirectoryReplica.zip?raw=true'
      configurationFunction: 'ActiveDirectoryReplica.ps1\\ActiveDirectoryReplica'
      properties: {
        Domain: Domain
        DomainCreds: {
          UserName: VmUsername
          Password: 'PrivateSettingsRef:VmPassword'
        }
      }
    }
  }
  dependsOn: [
    dc_Vm
    vm_dc_Environment_LocationAbbr_0_DSC
  ]
} */
