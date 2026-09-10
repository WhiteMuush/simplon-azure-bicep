// Copy to dev.bicepparam, which Git ignores.
using './main.bicep'

param prefix = 'mpweb'
param adminUsername = 'azureuser'

// Public key and source IP read from the environment by the Makefile scripts.
param sshKey = trim(readEnvironmentVariable('SSH_PUBLIC_KEY'))
param allowedSshSourceIp = readEnvironmentVariable('MY_SOURCE_IP')

param vmSize = 'Standard_D2_v3'
param instanceCount = 2
param minInstances = 2
param maxInstances = 4
