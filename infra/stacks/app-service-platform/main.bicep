@description('Naming prefix for the plan and the web app.')
param prefix string = 'mpapp'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Plan SKU. Standard S1 is the minimum that supports deployment slots.')
@allowed([
  'S1'
  'S2'
  'P1v3'
])
param planSku string = 'S1'

@description('Public demo container served in production.')
param productionImage string = 'nginxdemos/hello:latest'

@description('A different image in the staging slot, so the swap is visible.')
param stagingImage string = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'

// A web app name is a subdomain of azurewebsites.net, so it must be unique
// worldwide, hence uniqueString on the resource group id.
var webAppName = '${prefix}-${uniqueString(resourceGroup().id)}'
var planName = '${prefix}-plan'

resource plan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    // Required for a Linux plan.
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${productionImage}'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'SLOT_NAME'
          value: 'production'
        }
      ]
    }
  }
}

resource stagingSlot 'Microsoft.Web/sites/slots@2023-12-01' = {
  parent: webApp
  name: 'staging'
  location: location
  properties: {
    serverFarmId: plan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'DOCKER|${stagingImage}'
      alwaysOn: true
      appSettings: [
        {
          name: 'WEBSITES_PORT'
          value: '80'
        }
        {
          name: 'SLOT_NAME'
          value: 'staging'
        }
      ]
    }
  }
}

output productionUrl string = 'https://${webApp.properties.defaultHostName}'
output stagingUrl string = 'https://${stagingSlot.properties.defaultHostName}'
output swapCommand string = 'az webapp deployment slot swap --resource-group ${resourceGroup().name} --name ${webAppName} --slot staging --target-slot production'
