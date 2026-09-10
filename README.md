# simplon-azure-bicep

Infrastructure as code Bicep pour des ressources de calcul Azure : machines virtuelles, scale sets, App Service et Container Instances.

Consignes completes du TP : [docs/CONSIGNES.md](docs/CONSIGNES.md).

## Organisation du depot

| Dossier | Role |
|---|---|
| `infra/modules/` | Briques Bicep reutilisables. Jamais deployees seules, appelees par un stack. |
| `infra/stacks/` | Unites deployables. Un `main.bicep` et un resource group par stack. |
| `.github/workflows/` | Provisioning et destruction via GitHub Actions. |
| `docs/` | Consignes et documentation. |

## Stacks

| Stack | Ce qu'il deploie | Etape du TP |
|---|---|---|
| `linux-web-server` | VNet, subnet, NSG, IP publique, NIC, VM Ubuntu 22.04 en cle SSH, extension nginx | Etape 1 |
| `scalable-web-tier` | Load Balancer Standard, VMSS Linux, regles d'autoscale CPU | Etape 2 |
| `app-service-platform` | Plan App Service Linux S1, Web App conteneurisee, slot `staging` | Etape 3 |
| `container-group` | Groupe ACI de deux conteneurs, un web expose et un sidecar | Etape 4 |

## Conventions

- **Un resource group par stack**, nomme `rg-<alias>-tp104-<stack>`.
- **Aucun secret en dur.** Cle SSH publique et IP source passees au deploiement. Chaque stack fournit un `dev.sample.bicepparam` a copier en `dev.bicepparam`, ignore par Git.
- **Chaque stack est valide par une verification**, pas par un simple `Succeeded` au deploiement. La commande est dans le README du stack.

## Prerequis

```bash
make ssh-key        # genere ~/.ssh/tp-bicep-az104 si absente, avec les bonnes permissions
make ssh-key-show   # affiche la cle publique a passer en parametre
make my-ip          # affiche l'IP publique source a autoriser dans le NSG
```

La cle privee reste dans `~/.ssh/`, jamais dans le depot. Seule la cle publique circule, en parametre de deploiement.

## Cycle de travail

```bash
az bicep build --file infra/stacks/<stack>/main.bicep          # verifier la compilation
az deployment group what-if -g <rg> -f infra/stacks/<stack>/main.bicep -p <stack>/dev.bicepparam
az deployment group create  -g <rg> -f infra/stacks/<stack>/main.bicep -p <stack>/dev.bicepparam
az group delete -n <rg> --yes --no-wait                        # detruire
```

## Nettoyage

```bash
az group list --query "[?starts_with(name, 'rg-<alias>-tp104')].name" -o tsv \
  | xargs -I {} az group delete --name {} --yes --no-wait
```
