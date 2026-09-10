// Copy to dev.bicepparam, which Git ignores.
using './main.bicep'

param vmName = 'mpvmlinux'
param adminUsername = 'azureuser'

// Public key read from ~/.ssh/tp-bicep-az104.pub by the Makefile scripts.
param authenticationType = 'sshPublicKey'
param sshKey = trim(readEnvironmentVariable('SSH_PUBLIC_KEY')) # Do a make ssh-key

param ubuntuOSVersion = 'Ubuntu-2204'
// Standard_B1s is not offered in francecentral, an Azure Policy limits the
// allowed sizes, and the Dsv3 quota is full. Standard_D2_v3 satisfies all three.
param vmSize = 'Standard_D2_v3'
// Standard_D2_v3 is a generation 1 size, which rules out Trusted Launch.
param securityType = 'Standard'

param virtualNetworkName = 'vnet-linux-web-server'
param subnetName = 'snet-app'
param networkSecurityGroupName = 'nsg-linux-web-server'
