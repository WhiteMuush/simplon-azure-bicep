# simplon-azure-bicep

Infrastructure as code Bicep pour des ressources de calcul Azure : machine virtuelle, scale set avec autoscale, App Service et Container Instances.

Consignes completes du TP : [docs/CONSIGNES.md](docs/CONSIGNES.md).

## Demarrage

Trois commandes, rien a editer a la main.

```bash
make setup                          # questions de configuration, une seule fois
make what-if STACK=linux-web-server # ce qui va etre cree, sans rien creer
make deploy  STACK=linux-web-server # deployer
```

`make setup` verifie la connexion Azure, propose le resource group ou vous avez les droits, genere la cle SSH si elle manque, puis ecrit `config.env` a la racine. Ce fichier est local et ignore par Git : chacun a le sien, personne ne modifie de fichier suivi.

Sans `STACK=`, les cibles proposent la liste des stacks en interactif.

## Les cibles

```bash
make            # ou 'make help', liste tout
```

| Cible | Role |
|---|---|
| `setup` | Pose les questions et ecrit `config.env`. A lancer en premier. |
| `ssh-key` | Genere `~/.ssh/tp-bicep-az104` avec les bonnes permissions. |
| `ssh-key-show` | Affiche la cle publique. |
| `my-ip` | Affiche l'IP publique source au format CIDR. |
| `stacks` | Liste les stacks et leur resource group. |
| `check` | Formate, lint, puis fait valider le template par Azure. |
| `what-if` | Verifie les limites de l'abonnement, puis affiche les changements prevus. |
| `deploy` | Deploie le stack. |
| `destroy` | Supprime les ressources du stack, avec confirmation. |
| `outputs` | Affiche les sorties du stack deploye. |

## Les stacks

| Stack | Ce qu'il deploie | Etape du TP |
|---|---|---|
| `linux-web-server` | VNet, subnet, NSG, IP publique, NIC, VM Ubuntu 22.04 en cle SSH, extension nginx | Etape 1 |
| `scalable-web-tier` | Load Balancer Standard, VMSS Linux, autoscale CPU 70/30 | Etape 2 |
| `app-service-platform` | Plan App Service Linux S1, Web App conteneurisee, slot `staging` | Etape 3 |
| `container-group` | Groupe ACI de deux conteneurs, un web expose et un sidecar | Etape 4 |

Chaque stack a son `README.md` avec sa commande de verification, celle qui valide reellement l'exercice.

## Organisation

| Dossier | Role |
|---|---|
| `infra/stacks/` | Unites deployables. Un `main.bicep` et un `dev.bicepparam` par stack. |
| `infra/modules/` | Briques Bicep reutilisables, appelees par un stack. |
| `make/` | Un fichier `.mk` par domaine, sans logique. |
| `scripts/` | Un script par action, appele par une cible du Makefile. |
| `.github/workflows/` | Provisioning et destruction via GitHub Actions. |
| `docs/` | Consignes et documentation. |

## Comment c'est deploye

Chaque stack est une **deployment stack** Azure, pas un simple deploiement. La stack retient les ressources qu'elle gere, ce qui permet a `make destroy` de les supprimer sans toucher au resource group, partage et pre-cree sur cet abonnement.

`make what-if` lance d'abord un preflight : il compare ce que le template demande a ce que l'abonnement autorise vraiment, taille de VM offerte dans la region, quota de la famille, generation d'hyperviseur, SKU d'IP publique. Il attrape avant le deploiement ce qu'Azure ne signalerait qu'a la creation.

## Secrets

Rien de sensible n'entre dans le depot.

- La cle privee SSH reste dans `~/.ssh/`, seule la cle publique circule.
- La cle publique et l'IP source sont lues depuis l'environnement par les fichiers de parametres, via `readEnvironmentVariable`, et exportees par `scripts/lib.sh`. Rien a recopier.
- `config.env` et les vrais `*.bicepparam` sont ignores par Git. Chaque stack fournit un `dev.sample.bicepparam` commite en modele.

## Nettoyage

```bash
make destroy STACK=<stack>
```

A lancer en fin de seance sur chaque stack deploye. Le plan App Service S1 est facture meme sans trafic.
