# linux-web-server

Une VM Linux exposee sur Internet, servant une page nginx qui affiche son nom d'hote.

**Etape du TP :** Etape 1

## Ressources deployees

- Reseau virtuel et subnet dedie
- Groupe de securite reseau : SSH restreint a une IP source, HTTP ouvert
- IP publique Standard avec nom DNS
- Carte reseau
- VM Ubuntu 22.04 LTS, authentification par cle SSH uniquement
- Extension CustomScript installant nginx

## Deploiement

```bash
RG=rg-<alias>-tp104-linux-web-server
az group create -n $RG -l francecentral

cp dev.sample.bicepparam dev.bicepparam   # renseigner les vraies valeurs
az deployment group what-if -g $RG -f main.bicep -p dev.bicepparam
az deployment group create  -g $RG -f main.bicep -p dev.bicepparam
```

## Verification

```bash
curl http://$(az deployment group show -g $RG -n main --query properties.outputs.fqdn.value -o tsv)
```

La page doit contenir le nom d'hote de la VM. Une connexion SSH par mot de passe doit etre refusee, et une tentative depuis une autre IP doit etre bloquee par le NSG.

L'extension met 1 a 2 minutes a s'executer apres la fin du deploiement.

## Destruction

```bash
az group delete -n $RG --yes --no-wait
```
