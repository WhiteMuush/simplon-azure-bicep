# <img src="https://cdn.jsdelivr.net/gh/Azure/bicep@main/docs/images/BicepLogoImage.svg" height="28" alt="Bicep" align="center"/> Azure compute resources: infrastructure as code with Bicep <img src="https://cdn.jsdelivr.net/gh/devicons/devicon/icons/azure/azure-original.svg" height="28" alt="Azure" align="center"/>

![Bicep](https://img.shields.io/badge/Bicep-ARM-0078D4?logo=microsoftazure&logoColor=white)
![Azure CLI](https://img.shields.io/badge/Azure%20CLI-2.88-0078D4?logo=microsoftazure&logoColor=white)
![Deployment stacks](https://img.shields.io/badge/Deployment-stacks-5C2D91)
![Make](https://img.shields.io/badge/Make-driven-6D8086?logo=gnubash&logoColor=white)
![Ubuntu](https://img.shields.io/badge/Ubuntu-22.04-E95420?logo=ubuntu&logoColor=white)
![Status](https://img.shields.io/badge/status-deployed-brightgreen)

Four deployable stacks covering the AZ-104 compute path: a Linux VM behind an NSG, a scale set that scales on CPU, an App Service platform with a staging slot, and a container group. Every stack is a deployment stack, driven by `make`, with a preflight that checks the subscription limits before Azure does.

> Brief: [docs/CONSIGNES.md](docs/CONSIGNES.md)

## Getting started

Three commands, nothing to edit by hand.

```bash
make setup                          # configuration questions, once
make what-if STACK=linux-web-server # what would be created, creating nothing
make deploy  STACK=linux-web-server # deploy
```

`make setup` checks the Azure sign-in, offers the resource groups you may write to, generates the SSH key if it is missing, then writes `config.env` at the root. That file is local and Git ignored: everyone has their own, nobody edits a tracked file.

Without `STACK=`, the targets ask which stack to use.

## Targets

```bash
make            # same as 'make help', lists everything
```

| Target | Role |
|---|---|
| `setup` | Ask the questions and write `config.env`. Run this first. |
| `ssh-key` | Generate `~/.ssh/tp-bicep-az104` with the right permissions. |
| `ssh-key-show` | Print the public key. |
| `my-ip` | Print your public source IP in CIDR form. |
| `stacks` | List the stacks and their resource group. |
| `check` | Format, lint, then have Azure validate the template. |
| `what-if` | Check the subscription limits, then show the planned changes. |
| `deploy` | Deploy the stack. |
| `destroy` | Delete the resources of the stack, asks for confirmation. |
| `outputs` | Print the outputs of the deployed stack. |

## Stacks

| Stack | What it deploys | Lab step |
|---|---|---|
| `linux-web-server` | VNet, subnet, NSG, public IP, NIC, Ubuntu 22.04 VM with SSH key, nginx extension | Step 1 |
| `scalable-web-tier` | Standard load balancer, Linux scale set, CPU autoscale 70/30 | Step 2 |
| `app-service-platform` | Linux App Service plan S1, containerized web app, `staging` slot | Step 3 |
| `container-group` | Container group of two containers, one web and one sidecar | Step 4 |

Every stack has its own `README.md` with the verification command, the one that actually validates the exercise.

## Layout

| Directory | Role |
|---|---|
| `infra/stacks/` | Deployable units. One `main.bicep` and one `dev.bicepparam` per stack. |
| `infra/modules/` | Reusable Bicep building blocks, called by a stack. |
| `make/` | One `.mk` file per domain, no logic in them. |
| `scripts/` | One script per action, called by a Makefile target. |
| `.github/workflows/` | Provisioning and destruction through GitHub Actions. |
| `docs/` | Instructions and documentation. |

## How it is deployed

Every stack is an Azure **deployment stack**, not a plain deployment. The stack remembers the resources it manages, which lets `make destroy` remove them without touching the resource group, shared and pre-created on this subscription.

`make what-if` runs a preflight first: it compares what the template asks for with what the subscription really allows, VM size offered in the region, family quota, hypervisor generation, public IP SKU. It catches before deployment what Azure would only report at creation time.

## Secrets

Nothing sensitive enters the repository.

- The private SSH key stays in `~/.ssh/`, only the public key travels.
- The public key and the source IP are read from the environment by the parameter files, through `readEnvironmentVariable`, and exported by `scripts/lib.sh`. Nothing to copy by hand.
- `config.env` and the real `*.bicepparam` files are Git ignored. Every stack ships a `dev.sample.bicepparam` as a committed template.

## Cleanup

```bash
make destroy STACK=<stack>
```

Run it on every deployed stack at the end of a session. The S1 App Service plan bills even with no traffic.
