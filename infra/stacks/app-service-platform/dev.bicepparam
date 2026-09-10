using './main.bicep'

param prefix = 'mpapp'
param planSku = 'S1'
param productionImage = 'nginxdemos/hello:latest'
param stagingImage = 'mcr.microsoft.com/azuredocs/aci-helloworld:latest'
