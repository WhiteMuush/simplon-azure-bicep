# container-group

Un groupe de conteneurs ACI illustrant le partage du cycle de vie reseau entre un conteneur web et un sidecar.

**Etape du TP :** Etape 4

## Ressources deployees

- Groupe de conteneurs avec IP publique et nom DNS
- Conteneur principal : image web publique, expose sur le port 80
- Conteneur sidecar : sans port expose, ecrit un message horodate dans les logs en boucle
- CPU et memoire dimensionnes explicitement par parametre pour chaque conteneur

## Deploiement

```bash
RG=rg-<alias>-tp104-container-group
az group create -n $RG -l francecentral

cp dev.sample.bicepparam dev.bicepparam   # renseigner les vraies valeurs
az deployment group what-if -g $RG -f main.bicep -p dev.bicepparam
az deployment group create  -g $RG -f main.bicep -p dev.bicepparam
```

## Verification

```bash
curl http://<fqdn-du-groupe>
az container logs -g $RG -n <nom-groupe> --container-name <sidecar>
```

Le `curl` doit renvoyer la page de demonstration, et les logs du sidecar doivent montrer des lignes horodatees recentes.

## Destruction

```bash
az group delete -n $RG --yes --no-wait
```
