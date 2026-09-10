@description('Name of the container group.')
param groupName string = 'mpaci'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Public demo image of the container that answers on port 80.')
param webImage string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

@description('Image of the background container, which exposes no port.')
param sidecarImage string = 'mcr.microsoft.com/azurelinux/base/core:3.0'

@description('Size of the web container.')
param webCpu int = 1
param webMemoryInGb int = 1

@description('Size of the sidecar, deliberately smaller.')
param sidecarCpu int = 1
param sidecarMemoryInGb int = 1

// The DNS label is a subdomain of the region, so it must be unique worldwide.
var dnsNameLabel = '${groupName}-${uniqueString(resourceGroup().id)}'

// Writes a timestamped line every 30 seconds, visible with 'az container logs'.
var sidecarCommand = [
  '/bin/sh'
  '-c'
  'while true; do echo "$(date -Iseconds) sidecar alive"; sleep 30; done'
]

resource containerGroup 'Microsoft.ContainerInstance/containerGroups@2023-05-01' = {
  name: groupName
  location: location
  properties: {
    osType: 'Linux'
    restartPolicy: 'Always'
    containers: [
      {
        name: 'web'
        properties: {
          image: webImage
          ports: [
            {
              protocol: 'TCP'
              port: 80
            }
          ]
          resources: {
            requests: {
              cpu: webCpu
              memoryInGB: webMemoryInGb
            }
          }
        }
      }
      {
        // No 'ports' entry at all: the sidecar is reachable by nobody, it only
        // shares the network lifecycle of the group.
        name: 'sidecar'
        properties: {
          image: sidecarImage
          command: sidecarCommand
          resources: {
            requests: {
              cpu: sidecarCpu
              memoryInGB: sidecarMemoryInGb
            }
          }
        }
      }
    ]
    ipAddress: {
      type: 'Public'
      dnsNameLabel: dnsNameLabel
      // The port of the web container has to be repeated at group level.
      ports: [
        {
          protocol: 'TCP'
          port: 80
        }
      ]
    }
  }
}

output fqdn string = containerGroup.properties.ipAddress.fqdn
output curlCommand string = 'curl http://${containerGroup.properties.ipAddress.fqdn}'
output sidecarLogsCommand string = 'az container logs --resource-group ${resourceGroup().name} --name ${groupName} --container-name sidecar'
