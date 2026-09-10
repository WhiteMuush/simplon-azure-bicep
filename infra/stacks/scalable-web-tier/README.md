# scalable-web-tier

A redundant web tier behind a load balancer, scaling automatically on CPU.

**Lab step:** Step 2

## Resources

- Standard public load balancer, port 80 rule and TCP health probe
- Inbound NAT pool, to reach an individual instance over SSH
- Outbound rule, a Standard load balancer grants no implicit outbound access
- Linux scale set, 2 instances minimum, attached to the backend pool
- CustomScript extension installing nginx and stress-ng
- Autoscale: scale out above 70% CPU, scale in below 30%, over 5 minutes

## Deploy

```bash
make setup                    # once, writes config.env
make what-if STACK=scalable-web-tier
make deploy  STACK=scalable-web-tier
make outputs STACK=scalable-web-tier
```

## Verification

```bash
for i in $(seq 1 10); do curl -s http://<load-balancer-fqdn> | grep -o 'Instance : .*'; done
az vmss list-instances -g <rg> -n <vmss-name> -o table
```

Repeated calls must show different hostnames. To trigger the autoscale without real traffic, run `stress-ng` on one instance reached through the NAT pool.

## Destroy

```bash
make destroy STACK=scalable-web-tier
```
