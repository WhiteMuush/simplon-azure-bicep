# app-service-platform

A Linux App Service platform hosting a containerized web app with a staging slot.

**Lab step:** Step 3

## Resources

- Linux App Service plan, Standard S1 SKU, the minimum that supports slots
- Containerized web app on a public Docker image, HTTPS enforced
- `staging` deployment slot on the same plan, running a different image

## Deploy

```bash
make setup                    # once, writes config.env
make what-if STACK=app-service-platform
make deploy  STACK=app-service-platform
make outputs STACK=app-service-platform
```

## Verification

```bash
curl -I https://<webapp-name>.azurewebsites.net
curl -I https://<webapp-name>-staging.azurewebsites.net
az webapp deployment slot swap -g <rg> -n <webapp-name> --slot staging --target-slot production
```

Both URLs must answer 200 OK, and the content served in production must change after the swap.

Watch the cost: an S1 plan bills even with no traffic. Do not leave it running outside the sessions.

## Destroy

```bash
make destroy STACK=app-service-platform
```
