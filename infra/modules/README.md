# Modules

Briques Bicep reutilisables. Un module n'est jamais deploye seul : il est appele par un stack de `infra/stacks/`, recoit des `param` et renvoie des `output`.

| Module | Role | Sorties principales |
|---|---|---|
| `network.bicep` | NSG, reseau virtuel et subnet | ID du subnet |
| `linux-vm.bicep` | VM complete a partir d'un ID de subnet : IP publique, NIC, VM, extension | FQDN, commande SSH |
| `custom-script.bicep` | Extension CustomScript partagee entre la VM et le scale set | aucune |

Ces deux modules couvrent le bonus du TP : le stack `linux-web-server` appelle le module reseau une fois, puis le module VM plusieurs fois via une boucle `for` pilotee par un parametre `vmCount`.
