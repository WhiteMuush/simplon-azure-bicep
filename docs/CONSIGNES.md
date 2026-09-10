# Lab: Bicep for Azure Compute Resources

**Estimated duration:** 2 days (about 12 hours)

**Prerequisites**

- Bicep basics (`resource`, `param`, `var`, `output`, `az deployment group create`). See the Microsoft Learn module [Build your first Bicep file](https://learn.microsoft.com/en-us/training/modules/build-first-bicep-file/) if needed.
- Azure CLI installed.
- An Azure subscription with the Contributor role.

**Environment**

- macOS / Linux: native terminal.
- Windows: **Git Bash** (shipped with Git).
- VS Code with the Bicep extension is recommended.

**Reference material:** the Microsoft Learn path [AZ-104: Deploy and manage Azure compute resources](https://learn.microsoft.com/en-us/training/paths/az-104-manage-compute-resources/).

---

## Goals

The Microsoft Learn path above walks through VMs, scale sets, App Service plans, Web Apps and Container Instances using the **Azure portal** or the **Azure CLI**. In this lab you deploy the exact same resource types, but as **infrastructure as code with Bicep**:

- describe an infrastructure declaratively, in a versionable and reproducible way;
- understand the dependencies between Azure resources (network, security, compute) as expressed in a template;
- practice the Bicep language building blocks: parameters, variables, resources, implicit dependencies, outputs, modules and loops.

By the end of the lab you will be able to translate each of the 5 modules of the AZ-104 path into Bicep.

---

## Bicep for Terraform users

You already know Terraform, so the infrastructure as code concepts (resources, parameters, dependencies, modules, outputs) are familiar. What changes with Bicep is mostly the syntax and the absence of state.

| Terraform (HCL) | Bicep | Notes |
|---|---|---|
| `resource "type" "name" { }` | `resource name 'type@apiVersion' = { }` | Bicep requires the API version in the type; the symbolic name has no quotes |
| `variable "x" {}` then `var.x` | `param x type` then `x` | Bicep `param` is close to a Terraform `variable`, **not** `var`, which means something else |
| `local.x` | `var x = ...` | Inverted compared to Terraform intuition (`var` is a locally computed value, not an input). Classic trap |
| `output "x" {}` | `output x type = ...` | Same role, closer syntax |
| `resource_a.id` (reference) | `resourceA.id` | Almost identical: implicit dependencies in both languages |
| `module "x" { source = ... }` | `module x 'path.bicep' = { params: {} }` | Same logic |
| `.tfstate` file | *(no state file)* | Bicep/ARM reads the real state from Azure on every deployment. See reflection question 1 |
| `terraform plan` | `az deployment group what-if` | Direct equivalent |
| `terraform apply` | `az deployment group create` (or `az stack group create`) | |
| `terraform destroy` | No native command: `az group delete` or a Deployment Stack | See reflection question 5 |

The most disorienting point for a Terraform user: Bicep **compiles down to ARM JSON** (`az bicep build`). It is a transpiler, not an execution engine with a state graph like Terraform. That is why there is no direct `.tfstate` equivalent, and why this lab insists on the provisioning/destruction cycle in CI (reflection question 5): without state, it is up to you to know explicitly what must be destroyed.

---

## Setup

```bash
# Clone the lab repository
git clone <url-provided-by-the-trainer>
cd TP-Bicep-Azure

# Confirm you are in the right folder
pwd
ls
```

A local SSH key pair is required for the VM exercises. If you do not have one:

```bash
ssh-keygen -t ed25519 -C "tp-bicep-az104"
```

### Rules for the whole lab

- **One dedicated resource group per exercise**, named `rg-<your-alias>-tp104-exY` (for example `rg-jdupont-tp104-ex1`).
- **No hardcoded secrets**: the public SSH key and your source IP are passed as parameters at deployment time (`--parameters key=value`), never written in a `.bicep` file nor committed to Git with a real value.
- Every exercise ends with a verification (`curl`, `ssh`, or an `az` command). Without a passing verification, the exercise is not validated even if `az deployment group create` reports `Succeeded`.
- **Cleanup is mandatory at the end of each day** (see the last section).

---

## Step 1: Linux virtual machine (day 1, morning)

### Concept

Matches the module [*"Introduction to Azure virtual machines"*](https://learn.microsoft.com/en-us/training/modules/intro-to-azure-virtual-machines/). An Azure VM is more than the machine itself: it depends on a virtual network, a subnet, a network security group (NSG), a network interface (NIC) and, to reach it from the Internet, a public IP. In Bicep each of these is a resource of its own, wired to the others through references (`nic.id`, `vnet.id`) that create implicit dependencies. Azure Resource Manager then deploys them in the right order without you writing that order yourself.

### Exercise 1.1: network and security

Write a `main.bicep` file that deploys:

1. a virtual network (VNet) with a dedicated subnet;
2. a network security group (NSG) attached to the subnet, allowing:
   - port 22 (SSH) **only from your public IP** (a parameter, never `0.0.0.0/0`);
   - port 80 (HTTP) from anywhere.

> **Hint:** `Microsoft.Network/networkSecurityGroups` first, then `Microsoft.Network/virtualNetworks`, with the NSG referenced in the subnet's `networkSecurityGroup` property.

### Exercise 1.2: the VM and its extension

Extend the same template with:

3. a Standard SKU public IP with a DNS name;
4. a Linux VM (Ubuntu 22.04 LTS) authenticated by SSH key only (no password: `osProfile.linuxConfiguration.disablePasswordAuthentication: true`);
5. a `CustomScript` extension (`Microsoft.Compute/virtualMachines/extensions`) that installs `nginx` at startup and replaces the landing page with one showing the machine hostname.

Parameterize at minimum: the naming prefix, the VM size (`Standard_B1s` by default), the admin username, the SSH public key and the allowed source IP.

### Verification

```bash
az deployment group create --resource-group <rg> --template-file main.bicep --parameters ...
curl http://<public-ip-or-fqdn>
```

must return an HTML page containing the VM hostname. An SSH attempt using a password must be refused. An attempt from any IP other than yours must fail (blocked by the NSG).

> The extension takes 1 to 2 minutes to run after the deployment finishes, so wait before testing `curl`.

### Going further, step 1

- Attach a data disk (`dataDisks`) to the VM.
- Expose a ready to paste `ssh` command as an `output`.
- Try `az deployment group create --confirm-with-what-if` to preview what will be created before confirming.

---

## Step 2: availability and scaling (day 1, afternoon)

### Concept

Matches the module [*"Configure virtual machine availability"*](https://learn.microsoft.com/en-us/training/modules/configure-virtual-machine-availability/). A single VM is a single point of failure. Replace it with a **Virtual Machine Scale Set** (VMSS) behind a **Load Balancer**, with **autoscale** rules that add or remove instances based on load.

### Exercise 2.1: load balancer and VMSS

1. a public Standard Load Balancer, with a load balancing rule on port 80 and a TCP health `probe`;
2. a Linux VMSS (`Microsoft.Compute/virtualMachineScaleSets`), at least 2 instances, attached to the load balancer backend pool;
3. the same `CustomScript` extension as step 1, so you can see the load distribution (hostname displayed).

> **Hint:** the VMSS SKU (name, tier, capacity) is defined at the resource's `sku` level, not inside `properties`.

### Exercise 2.2: autoscale

4. an autoscale rule (`Microsoft.Insights/autoscalesettings`) based on CPU: scale out if average CPU goes above 70% for 5 minutes, scale in if CPU drops below 30% for 5 minutes, with a parameterizable minimum and maximum instance count.

> **Hint:** the autoscale rule's `targetResourceUri` must point to the VMSS ID (`vmss.id`).

### Verification

```bash
curl http://<load-balancer-fqdn>
```

run several times must show different hostnames. To observe autoscale without waiting for real traffic, install `stress-ng` in your extension and run it manually on one instance over SSH (plan a way to reach an individual instance: look at `inboundNatPools` on the load balancer).

### Going further, step 2

- Add a schedule based autoscale rule (predictable scale out in the morning, scale in in the evening).
- Run `az vmss list-instances` during a load spike to watch the scale out live.

---

## Step 3: App Service plan and Web App (day 2, morning)

### Concept

Matches the modules [*"Configure Azure App Service plans"*](https://learn.microsoft.com/en-us/training/modules/configure-app-service-plans/) and [*"Configure Azure App Service"*](https://learn.microsoft.com/en-us/training/modules/configure-azure-app-services/). An App Service plan defines the compute capacity (SKU, OS); one or more Web Apps attach to it. **Deployment slots** let you stage a new version alongside production, then swap without downtime.

### Exercise 3.1: plan and Web App

1. a Linux App Service plan, **Standard S1 SKU minimum** (required for slots);
2. a containerized Web App (a public demo Docker image) attached to that plan, with HTTPS enforced.

> **Hint:** a Web App name must be **globally unique** (subdomain `*.azurewebsites.net`), so use `uniqueString(resourceGroup().id)` in the name. The image is set in `siteConfig.linuxFxVersion` using the `DOCKER|<image>` format.

### Exercise 3.2: deployment slot

3. a slot named `staging`, on the same plan (child resource `Microsoft.Web/sites/slots`, `parent: webApp`), able to host a different version.

### Verification

```bash
curl -I https://<webapp-name>.azurewebsites.net
curl -I https://<webapp-name>-staging.azurewebsites.net
```

must both answer `200 OK`. Perform a swap with `az webapp deployment slot swap` and check that the content served in production changed.

> **Cost:** an S1 plan bills even with no traffic. Do not leave it running outside the sessions.

### Going further, step 3

- Add `appSettings` (environment variables) that differ between production and staging.
- Configure autoscale on the App Service plan itself (`Microsoft.Insights/autoscalesettings` targeting the plan).

---

## Step 4: Azure Container Instances (day 2, afternoon)

### Concept

Matches the module [*"Configure Azure Container Instances"*](https://learn.microsoft.com/en-us/training/modules/configure-azure-container-instances/). ACI runs one or more containers without managing a VM or a cluster. A **container group** shares the same network lifecycle: it is the deployment unit, not the individual container.

### Exercise 4.1: a group of two containers

Deploy a `Microsoft.ContainerInstance/containerGroups` made of:

1. a main container running a public demo web image, exposed on port 80 with a public DNS name;
2. a "sidecar" container with no exposed port, running in the background (for example a loop writing a message to the logs every 30 seconds), to illustrate the shared network lifecycle of the group.

Size the CPU and memory of each container explicitly, through parameters.

> **Hint:** the public DNS name (`properties.ipAddress.dnsNameLabel`) must also be globally unique. A container with no exposed port simply has no `ports` entry, but the main container's port must be repeated at group level (`ipAddress.ports`).

### Verification

```bash
curl http://<container-group-fqdn>
az container logs --resource-group <rg> --name <group-name> --container-name <sidecar>
```

The `curl` must return the demo page. The sidecar logs must show recent timestamped lines.

### Going further, step 4

- Add an `azureFile` volume shared between both containers.
- Pass environment variables (`environmentVariables`) to the main container.

---

## Bonus: modularize your code (if time allows)

Take step 1 and split the template into two reusable **Bicep modules**:

- `network.bicep`: NSG plus VNet/subnet, exposing the subnet ID as an output;
- `vm.bicep`: a complete VM (public IP, NIC, VM, extension) built from a subnet ID received as a parameter.

In an orchestrating `main.bicep`, call the network module once, then call the VM module **several times through a `for` loop**, driven by a `vmCount` parameter.

Run `az deployment group what-if` before applying a change to `vmCount`, to see what Azure plans to create, modify or delete without actually doing it.

---

## Reflection: Terraform vs Bicep (mandatory)

You have already provisioned this kind of Azure resource with Terraform in a previous lab. Answer the following **5 questions** in a `REFLEXION-TERRAFORM-VS-BICEP.md` file at the root of your repository. A few sentences per question is enough: the goal is to compare both tools on concrete points you actually ran into, not to recite a course.

1. **State management.** Terraform keeps a state file (`.tfstate`) separate from the real infrastructure; Bicep has none and relies only on what Azure Resource Manager sees in the resource group. What concrete advantages and drawbacks does this bring (drift risk, state locking when several people work together, complexity of configuring a remote backend, and so on)?

2. **Multi-cloud portability.** Terraform can drive several providers (AWS, GCP, Azure) with the same tool; Bicep is Azure specific. In which context would this Terraform advantage be decisive for you, and in which context would it be irrelevant?

3. **Support for new Azure services.** Bicep, being the official Microsoft tool compiled straight to ARM, usually gets day one support for new Azure resources and APIs; the Terraform `azurerm` provider depends on extra work from HashiCorp and the community and can lag behind. Have you run into (or can you imagine) a situation where that delay would be a real problem?

4. **Syntax and module ecosystem.** Compare the readability of HCL (Terraform) and Bicep on the resources you wrote in both labs, along with the richness of their reusable module ecosystems (Terraform Registry versus community and first party Bicep modules). Which felt faster to write, and why?

5. **Provisioning/destruction cycle in CI.** You now have a GitHub Actions pipeline with a provisioning workflow (`bicep-provision.yml`) and a destruction workflow (`bicep-destroy.yml`), much like `terraform apply` / `terraform destroy`. Terraform knows what to destroy thanks to its state; Bicep/ARM has no such memory, so your destruction workflow must explicitly target a resource group. Which of the two models seems safer to integrate into a CI shared by the whole cohort, and why?

---

## Expected deliverables

The submission is **the URL of your GitHub repository**, containing:

- the Bicep code for every exercise (`.bicep` files plus parameter files, with no plaintext secrets);
- both workflows `.github/workflows/bicep-provision.yml` and `bicep-destroy.yml`, each **run at least once** and visible in the repository's **Actions** tab (one successful provisioning run, followed by one successful destruction run);
- the `REFLEXION-TERRAFORM-VS-BICEP.md` file at the root, answering the 5 questions above.

---

## Final cleanup

At the end of the lab, delete **all** your resources:

```bash
az group list --query "[?starts_with(name, 'rg-<your-alias>-tp104')].name" -o tsv | xargs -I {} az group delete --name {} --yes --no-wait
```

---

*DevOps Azure training, Simplon*
