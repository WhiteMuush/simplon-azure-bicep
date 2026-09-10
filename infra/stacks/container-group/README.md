# container-group

A container group showing how a web container and a sidecar share one network lifecycle.

**Lab step:** Step 4

## Resources

- Container group with a public IP and a DNS name
- Main container: public demo web image, exposed on port 80
- Sidecar container: no exposed port, writes a timestamped line every 30 seconds
- CPU and memory sized explicitly, through parameters, for each container

## Deploy

```bash
make setup                    # once, writes config.env
make what-if STACK=container-group
make deploy  STACK=container-group
make outputs STACK=container-group
```

## Verification

```bash
curl http://<container-group-fqdn>
az container logs -g <rg> -n <group-name> --container-name sidecar
```

The `curl` must return the demo page, and the sidecar logs must show recent timestamped lines.

## Destroy

```bash
make destroy STACK=container-group
```
