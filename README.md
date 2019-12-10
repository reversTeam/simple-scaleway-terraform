# Start quickly with terraform on Scaleway

Simple Scaleway Terraform aims to abstract terraform in order to simplify the handling.

I'm not sure that everything is good to take, I learn terraform myself while I do this rest. But I think it might help other people understand terraform, and the Scaleway platform.

Here is the nomenclature of the project this one is only an example not structuring for the moment.
You will need to modify the following files: `main.tf` and` terraform.tfvars` to suit your needs
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

I wanted to start with terraform, I realized that the sources of information about Scaleway are not yet sufficiently accessible.
I also think that the subject could motivate some of you to improve this model, or even to invalidate it quickly.


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

### TIPS:
With a `backend.tf` file you can then store your terraform states remotely, as in Scaleway s3. (free offer for the first 75 GB, storage and bandwidth).

```
terraform {
  backend "s3" {
    bucket      = "your-bucket-name"
    key         = "your-infrastructure-name.tfstate"
    region      = "fr-par"                               # ["fr-par" or "nl-ams", warsovie in next time]
    endpoint    = "https://s3.fr-par.scw.cloud"          # warning : region is redonded on the endpoint value
    access_key = "your_access_key"                       # generate token on https://console.scaleway.com
    secret_key = "your_secret_key" 
    skip_credentials_validation = true
    skip_region_validation = true
  }
}
```

You will also be able to integrate terraform directly into your pipeline. Here is an example of an internship for `gitlab_ci.yml`. These lines allow to run the tests, only if the terraform file changes and if it is submitted on master.
These lines will have to be adapted to your use.
```
image: golang:latest

variables:
  REPO_NAME: github.com/reversTeam/simple-scaleway-terraform
  ARTIFACTS_DIR: artifacts
  BINARY_FILE: ffs
  TERRAFORM_VERSION: "0.12.17"

before_script:
    - apt-get update
    - apt-get install -y unzip libprotobuf-dev protobuf-compiler
    ## Install go environment
    - go get -u github.com/golang/dep/cmd/dep
    - go get -u github.com/golang/protobuf/{proto,protoc-gen-go}

    ## Install Terraform
    - cd /tmp
    - wget https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    - unzip terraform_${TERRAFORM_VERSION}_linux_amd64.zip
    - mv terraform /usr/local/bin/
    - cd $CI_PROJECT_DIR/terraform
    - terraform init

stages:
  - validate
  - plan
  - apply

validate:
  stage: validate
  script:
    - cd $CI_PROJECT_DIR/terraform
    - terraform validate
  only:
    refs:
      - master
    changes:
      - terraform/**/*

plan:
  stage: plan
  script:
    - cd $CI_PROJECT_DIR/terraform
    - terraform plan -out "planfile"
  artifacts:
    paths:
      - $CI_PROJECT_DIR/terraform/planfile
  dependencies:
    - validate
  only:
    refs:
      - master
    changes:
      - terraform/**/*

apply:
  stage: apply
  script:
    - cd $CI_PROJECT_DIR/terraform
    - terraform apply -input=false "planfile"
  dependencies:
    - plan
  when: manual
  only:
    refs:
      - master
    changes:
      - terraform/**/*
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
    web = module.web.nodes                // Transmitted the instance setup by the web module
    proxy = module.database.nodes         // Transmitted the instance setup by the proxy module
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

[...]

# services
service = {
  "${service_name}" = { # quoted for exposed vars, need remove this "${}"
    networks = {
       hosted = ["x", "y"]
      linked = ["z"]
    }
  }
  #[...]
}
# networks
networks = {
  x = { # like used network in "${service_name}"
    all = [
      {
        action = "accept|drop"
        port = 80
        interface = "address|public|address|or real ip 123.45.67.89/32"
      },
      #[...]
    ]
    in = []
    out = []
  },
}
```


## Define your infrastructure
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
