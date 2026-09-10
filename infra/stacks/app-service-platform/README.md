# app-service-platform

Une plateforme App Service Linux hebergeant une Web App conteneurisee avec un slot de preproduction.

**Etape du TP :** Etape 3

## Ressources deployees

- Plan App Service Linux, SKU Standard S1 (minimum requis pour les slots)
- Web App conteneurisee sur image Docker publique, HTTPS force
- Slot de deploiement \`staging\` sur le meme plan

## Deploiement

```bash
RG=rg-<alias>-tp104-app-service-platform
az group create -n $RG -l francecentral

cp dev.sample.bicepparam dev.bicepparam   # renseigner les vraies valeurs
az deployment group what-if -g $RG -f main.bicep -p dev.bicepparam
az deployment group create  -g $RG -f main.bicep -p dev.bicepparam
```

## Verification

```bash
curl -I https://<nom-webapp>.azurewebsites.net
curl -I https://<nom-webapp>-staging.azurewebsites.net
az webapp deployment slot swap -g $RG -n <nom-webapp> --slot staging --target-slot production
```

Les deux URL doivent repondre 200 OK, et le contenu servi en production doit changer apres le swap.

Attention au cout : un plan S1 est facture meme sans trafic. Ne pas le laisser actif en dehors des seances.

## Destruction

```bash
az group delete -n $RG --yes --no-wait
```
