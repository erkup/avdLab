# This deployment provides building blocks for a simple Azure Virtual Desktop proof of concept

To make the environment scalable & help align with [Azure Cloud Adoption Framework](https://aka.ms/caf) landing zone concepts, by default the resources are deployed across 2 Azure subscriptions.

## Please note

- **By default "Platform" subscription resources are deployed in current subscription context.**
- The subscription ID where AVD resources will be deployed needs to be passed as a parameter.
- If you'd like to deploy both platform & AVD resources to the same subscription, you can pass the same subscription ID for both parameters.
- This is a proof of concept deployment, and is not intended for production use.

The following Azure components are deployed ![avd Diagram](/img/avdPilotFramework.svg)

These templates borrow heavily from the [AVD What the Hack repo](https://github.com/microsoft/WhatTheHack/tree/master/037-AzureVirtualDesktop)
