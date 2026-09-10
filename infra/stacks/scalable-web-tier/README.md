# scalable-web-tier

Un etage web redonde derriere un load balancer, avec mise a l'echelle automatique sur le CPU.

**Etape du TP :** Etape 2

## Ressources deployees

- Load Balancer Standard public, regle sur le port 80 et sonde de sante TCP
- Pool NAT entrant pour joindre une instance individuelle en SSH
- Virtual Machine Scale Set Linux, 2 instances minimum, rattache au backend pool
- Extension CustomScript affichant le nom d'hote
- Regle d'autoscale : scale-out au-dessus de 70 % de CPU, scale-in sous 30 %, sur 5 minutes

## Deploiement

```bash
RG=rg-<alias>-tp104-scalable-web-tier
az group create -n $RG -l francecentral

cp dev.sample.bicepparam dev.bicepparam   # renseigner les vraies valeurs
az deployment group what-if -g $RG -f main.bicep -p dev.bicepparam
az deployment group create  -g $RG -f main.bicep -p dev.bicepparam
```

## Verification

```bash
for i in $(seq 1 10); do curl -s http://<fqdn-du-load-balancer> | grep -o 'Hote : .*'; done
az vmss list-instances -g $RG -n <nom-vmss> -o table
```

Les appels repetes doivent afficher des noms d'hote differents. Pour declencher l'autoscale sans trafic reel, lancer `stress-ng` sur une instance via le pool NAT.

## Destruction

```bash
az group delete -n $RG --yes --no-wait
```
