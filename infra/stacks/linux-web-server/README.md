# linux-web-server

A Linux VM exposed on the Internet, serving an nginx page that shows its hostname.

**Lab step:** Step 1

## Resources

- Virtual network and a dedicated subnet
- Network security group: SSH restricted to one source IP, HTTP open
- Standard public IP with a DNS name
- Network interface
- Ubuntu 22.04 LTS VM, SSH key authentication only
- CustomScript extension installing nginx

## Deploy

```bash
make setup                    # once, writes config.env
make what-if STACK=linux-web-server
make deploy  STACK=linux-web-server
make outputs STACK=linux-web-server
```

## Verification

```bash
curl "$(make outputs STACK=linux-web-server | python3 -c 'import json,sys; print(json.load(sys.stdin)["fqdn"]["value"])')"
```

The page must contain the VM hostname. An SSH attempt using a password must be refused, and an attempt from another IP must be blocked by the NSG.

The extension takes 1 to 2 minutes to run after the deployment finishes.

## Destroy

```bash
make destroy STACK=linux-web-server
```
