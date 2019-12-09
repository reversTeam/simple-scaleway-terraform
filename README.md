# simple-scaleway-terraform

Start Quickly with Scaleway Terraform
```
├── README.md
├── main.tf
├── modules
│   └── replicator
│       ├── main.tf
│       ├── securityGroups.tf
│       └── variables.tf
├── terraform.tfvars
└── variables.tf
```

## Why this project ?

 - Because I start using terraform
 - Because it's fun
 - Because terraform on scaleway need to has more accessible
 - Because why not


## What is it ?

It's a simple module for improve your experience with terraform on scaleway, I just start terraform, maybe later I realise all this project it's a mistake, it's not exclude.

The goal is start quickly your infrastructure and abstract networks rules with a simple configuration.


## Requirement

 - Install terraform
 - Scaleway Account:
    - Setup access key / secret key
    - Export access key / secret key


Export SCW terraform configuration
```
export TF_VAR_scw_api_key="<YOUR_SCW_API_KEY>"
export TF_VAR_scw_secret_key="<YOUR_SCW_SECRET_KEY>"
export TF_VAR_scw_org_id="<YOUR_SCW_API_KEY>" # Optional
```

Update the image id in `terraform.tfvars`

```
$> terraform init
$> terraform plan         # no cost, just show the deploying result
$> terraform apply        # this action deploy your infrastructure on Scaleway, see the scaleway pricing before run
```

## Example

We want to create a scalable wordpress, with secure network database, loadbalancer and scalable wordpress worker.

For that look the `main.tf` content file, for loading modules.

In this file we see, the provider configuration (other cloud provider, is not implemented yet)

```
provider "scaleway" {
  access_key = var.scw_api_key
  secret_key = var.scw_secret_key
  organization_id = var.scw_org_id 
  zone       = var.scw_zone
  region     = var.scw_region
  version = "~> 1.11"
}
```
Note: the scaleway token is trasmited by environment variable


```
module "database" {                       // Name of pool type
  source = "./modules/replicator"         // The base module for all pool type
  module_name = "database"                // Name of module again, if someone knows how to use a module name var
  project = var.project                   // Your project, or client name
  cluster = var.cluster                   // The cluster, for manage more in futur
  region = var.scw_region                 // The region where you want deploy your infrastructure

  infra = var.infra                       // The global configuration for each pool type (cf. terraform.tfvars)
  services = var.services                 // The global configuration for services on the instance, use by infra (cf. terraform.tfvars)
  networks = var.networks                 // The global configuration for each network, use by services (cf. terraform.tfvars)

  pools = {
    web = module.web.nodes
    proxy = module.database.nodes
  }
}

'[...]'
```

Content file `terraform.tfvars`
```
# scw region
scw_region = "fr-par"

# scw zone
scw_zone = "fr-par-1"

# project name
project = "default"

# cluster id
cluster = 1
```


# Define your infrastructure
The infrastructure is required for discribe your node type (beacause it's scalable), and what service are installed on them.
```
infra = {
  proxy = {                  # infra pool type name, it's a segmentation for scale
    scale = 1                # Number of node for this type
    public_ip = true         # Your instance required an external IP?
    image = "<IMG_ID>"       # The id of your image (look a packer for create your image with scaleway)
    type = "DEV1-S"          # The commercial instance type, look the scaleway instance catalog
    services = [ "nginx" ]   # The service you want to deploy on this server
  },
  [...]
}
```

## Define the networks for your services
The service it's required, for link hardware and network. When you write in `infra.*.service["x"]`, `x` is a service and it's necessary to describe, what network is used by this service. The distinction is required between `linked` and `hosted` network for know if your service is a `psql` or is a soft who `use psql`. 
```
services = {
  nginx = {
    networks = {
      # ssh_public and ssh_private it's a tricks
      hosted = ["public", "ssh_public"]  # this service is not connected to the other
      linked = ["web", "ssh_private"]    # this service is linked with other services
    }
  }
  [...]
}
```

## Define what service need what network rule

You need to describe the network by service, with that you can use different service in single instance, and in the futur, you can move your service to the other pool.

```
networks = {
  public = {
    all = [                     # use by nginx, it's for internet expose
      {
        action = "accept"      # accept connexion, drop it's possible
        port = 80              # the port used for the service
        interface = "address"  # Interface address == 0.0.0.0/0, public for public ip, private
      },
      {
        action = "accept"
        port = 443
        interface = "address"
      }
    ]
    in = []                    # if you want to drop or accept only for the inbounding
    out = []                   # if you want to drop or accept only for the outbounding
  },
  web = {
    all = [
      {
        action = "accept"
        port = 8080
        interface = "private" # address || public || private || IP/range
      }
    ]
    in = []
    out = []
  },
  database =    { ... },
  ssh_public =  { ... },
  ssh_private = { ... ],
}
```
