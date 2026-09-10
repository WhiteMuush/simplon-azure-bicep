# TP Bicep : ressources de calcul Azure

Infrastructure as code Bicep couvrant le parcours AZ-104 "Deployer et gerer les ressources de calcul Azure".

## Contenu prevu

1. VM Linux : VNet, subnet, NSG, IP publique, VM Ubuntu 22.04 en cle SSH, extension CustomScript (nginx)
2. Disponibilite : Load Balancer Standard, VMSS, regles d'autoscale CPU
3. App Service : plan Linux S1, Web App conteneurisee, slot `staging`
4. Container Instances : groupe de deux conteneurs (web + sidecar)
5. Bonus : decoupage en modules `network.bicep` / `vm.bicep` avec boucle `for`

## Regles

- Un resource group par exercice : `rg-<alias>-tp104-exY`
- Aucun secret en dur : cle SSH publique et IP source passees en `--parameters`
- Nettoyage systematique en fin de seance

## Livrables

- Code Bicep + fichiers de parametres
- Workflows `.github/workflows/bicep-provision.yml` et `bicep-destroy.yml`, executes au moins une fois
- `REFLEXION-TERRAFORM-VS-BICEP.md` a la racine
