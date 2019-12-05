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

### Why this project ?

 - Because I start using terraform
 - Because it's fun
 - Because terraform on scaleway need to has more accessible
 - Because why not


### What is it ?

It's a simple module for improve your experience with terraform on scaleway, I just start terraform, maybe later I realise all this project it's a mistake, it's not exclude.

The goal is start quickly your infrastructure and abstract networks rules with a simple configuration.


### Requirement

 - Install terraform
 - Scaleway Account:
    - Setup access key / secret key
    - Export access key / secret key

### Example

Export SCW configuration
```
export TF_VAR_scw_api_key="<YOUR_SCW_API_KEY>"
export TF_VAR_scw_secret_key="<YOUR_SCW_SECRET_KEY>"
export TF_VAR_scw_org_id="<YOUR_SCW_API_KEY>" # Optional
```

Content file of `terraform.tfvars`
```
# scw region
scw_region = "fr-par"

# scw zone
scw_zone = "fr-par-1"

# project name
project = "default"

# cluster id
cluster = 1

# define your infrastructure
# 5 instances:
#   - 1 nginx for lb
#   - 3 wordpress worker
#   - 1 psql database
infra = {
  proxy = {
    scale = 1
    public_ip = true            # This instance require a public ip
    image = "<IMAGE_ID>"        # Use your image id of nginx for example
    type = "DEV1-S"             # Select your instance type
    services = [ "nginx" ]      # List the services on this instance
  },
  web = {
    scale = 3
    public_ip = false           # This instance don't need to have a public ip
    image = "<IMAGE_ID>"        # Use your image id of wordpress for example
    type = "DEV1-S"
    services = [ "wordpress" ] 
  },
  database = {
    scale = 1
    public_ip = false           # This instance don't need to have a public ip
    image = "<IMAGE_ID>"        # Use your image id of psql for example
    type = "DEV1-S"
    services = [ "psql" ]
  },
}

## define the networks link services 
services = {
  nginx = { # Nginx service use a public network and web network
    networks = ["public",  "web"]
  }
  wordpress = { # Wordpress service use a database network and web network
    networks = ["web", "database"]
  }
  psql = { # Wordpress service use a database network
    networks = ["database"]
  }

}

## define each network
networks = {
  public = {
    all = [
      {
        action = "accept"
        port = 80
        interface = "address"
      },
      {
        action = "accept"
        port = 443
        interface = "address"
      }
    ]
    in = []
    out = []
  },
  web = {
    all = [
      {
        action = "accept"
        port = 8080
        interface = "private"
      }
    ]
    in = []
    out = []
  },
  database = {
    all = [
      {
        action = "accept"
        port = 5432
        interface = "private"
      } 
    ]
    in = []
    out = []
  }
}
```

### Result

Security Group auto create and linked with your service description
```
  # module.web.scaleway_security_group.security_group will be created
  + resource "scaleway_security_group" "security_group" {
      + description             = "Allow all network configuration for 1"
      + enable_default_security = true
      + id                      = (known after apply)
      + inbound_default_policy  = "accept"
      + name                    = "default-web-fr-par-c1"
      + outbound_default_policy = "accept"
    }

  # module.web.scaleway_security_group_rule.self_inbound[0] will be created
  + resource "scaleway_security_group_rule" "self_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.web.scaleway_security_group_rule.self_inbound[1] will be created
  + resource "scaleway_security_group_rule" "self_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 5432
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.web.scaleway_security_group_rule.self_outbound[0] will be created
  + resource "scaleway_security_group_rule" "self_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.web.scaleway_security_group_rule.self_outbound[1] will be created
  + resource "scaleway_security_group_rule" "self_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 5432
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

```


```
  # module.proxy.scaleway_security_group_rule.self_inbound[0] will be created
  + resource "scaleway_security_group_rule" "self_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = "0.0.0.0"
      + port           = 80
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.self_inbound[1] will be created
  + resource "scaleway_security_group_rule" "self_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = "0.0.0.0"
      + port           = 443
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.self_inbound[2] will be created
  + resource "scaleway_security_group_rule" "self_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.self_outbound[0] will be created
  + resource "scaleway_security_group_rule" "self_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = "0.0.0.0"
      + port           = 80
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.self_outbound[1] will be created
  + resource "scaleway_security_group_rule" "self_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = "0.0.0.0"
      + port           = 443
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.self_outbound[2] will be created
  + resource "scaleway_security_group_rule" "self_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.services_inbound[0] will be created
  + resource "scaleway_security_group_rule" "services_inbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }

  # module.proxy.scaleway_security_group_rule.services_outbound[0] will be created
  + resource "scaleway_security_group_rule" "services_outbound" {
      + action         = "accept"
      + direction      = "inbound"
      + id             = (known after apply)
      + ip_range       = (known after apply)
      + port           = 8080
      + protocol       = "TCP"
      + security_group = (known after apply)
    }
```



