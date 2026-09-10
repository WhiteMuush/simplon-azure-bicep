# Modules

Reusable Bicep building blocks. A module is never deployed on its own: a stack of `infra/stacks/` calls it, passes `param` values and reads its `output`.

| Module | Role | Main outputs |
|---|---|---|
| `network.bicep` | NSG, virtual network and subnet | Subnet ID |
| `custom-script.bicep` | CustomScript extension shared by the VM and the scale set | none |

These modules cover the bonus of the lab: the `linux-web-server` stack calls the network module once, then the VM module several times through a `for` loop driven by a `vmCount` parameter.
