# Usage

## Environment Variables
> Environment variables can also be used to set terraform variables when running the `terraform apply` command using the format `TF_VAR_name`.

Configure terraform variables as needed by updating the `main.tfvars` file:

### Terraform Variables

| Variable     | Description         | Default         |
| ------------ | ------------------- | --------------- |
| `do_domain` | Public domain used for the faasd gateway | None |
| `do_ipv4_float` | Digitalocean IPv4 Floating IP to attach to droplet | None |
| `do_ssh_key` | Digitalocean sshkey in your account  | None |
| `do_region` | The Digitalocean region where the faasd droplet will be created | `nyc2` |
| `do_registry_auth` | Digitalocean auth for their container registry | None |
| `do_subdomain` | Public subdomain used for the faasd gateway | None |
| `do_token` | Digitalocean API token | None |
| `environment` | Digitalocean API token | None |
| `letsencrypt_email` | Email used by when ordering TLS certificate from Letsencrypt | None |
| `ssh_key_file` | Path to public SSH key file | None |
| `cloud_template` | Filename of the cloud template to use | None |

### GitHub Secret Variables

#### Organization Variables

| Variable     | Description         | Default         |
| ------------ | ------------------- | --------------- |
| `DO_API_TOKEN` | Digitalocean API token | None |
| `DO_CONTAINER_REGISTRY_AUTH_TOKEN` | "" | None |
| `DO_CONTAINER_REGISTRY_PREFIX` | "" | None |
| `DO_SPACES_KEY_ID` | "" | None |
| `DO_SPACES_REGION` | "" | None |
| `DO_SPACES_SECRET_ID` | "" | None |
| `DO_SPACES_URI` | "" | None |
| `GH_ACTION_TOKEN` | "" | None |
| `OPENFAAS_URL` | "" | None |

#### Repository Variables
| Variable     | Description         | Default         |
| ------------ | ------------------- | --------------- |
| `PROD_DOMAIN` | "" | "`orionsbelt.ca`" |
| `PROD_DO_SSH_KEY_NAME` | "" | None |
| `PROD_IPV4` | "" | None |
| `PROD_LETSENCRYPT_EMAIL` | "" | None |
| `PROD_REGION` | "" | `nyc2` |
| `PROD_SUBDOMAIN` | "" | `antenna` |
| `SLACK_CLIENT_ID` | "" | None |
| `SLACK_CLIENT_SECRET` | "" | None |
| `SLACK_STATE_SECRET` | "" | None |
| `STAGING_DOMAIN` | "" | "`orionsbelt.ca`" |
| `STAGING_DO_SSH_KEY_NAME` | "" | None |
| `STAGING_IPV4` | "" | None |
| `STAGING_LETSENCRYPT_EMAIL` | "" | None |
| `STAGING_REGION` | "" | `nyc1` |
| `STAGING_SUBDOMAIN` | "" | `staging` |


## Terraform Output
```
droplet_ip = 178.128.39.201
gateway_url = https://faasd.example.com/
login_cmd = faas-cli login -g https://faasd.example.com/ -p rvIU49CEcFcHmqxj
password = rvIU49CEcFcHmqxj
```
