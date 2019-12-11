# scw region
scw_region = "fr-par"

# scw zone
scw_zone = "fr-par-1"

# project name
project = "default"

# cluster id
cluster = 1

# ssh key path without passphrase
keypath = "~/.ssh/deployment"

# define your infrastructure
infra = {
  proxy = {
    scale = 1
    public_ip = true
    image = "<IMAGE_ID>"
    type = "DEV1-S"
    services = [ "nginx" ]
  },
  web = {
    scale = 3
    public_ip = false
    image = "<IMAGE_ID>"
    type = "DEV1-S"
    services = [ "wordpress" ] 
  },
  database = {
    scale = 1
    public_ip = false
    image = "<IMAGE_ID>"
    type = "DEV1-S"
    services = [ "psql" ]
  },
}

## define the networks link services 
services = {
  nginx = {
    networks = {
      hosted = ["public", "ssh_public"]
      linked = ["web", "ssh_private"]
    }
    install = [
      "apt-get install -y nginx",
    ]
    run = [
      "/etc/init.d/nginx start"
    ]
  }
  wordpress = {
    networks = {
      hosted = ["web", "ssh_private"]
      linked = ["database"]
    }
    install = []
    run = []
  }
  psql = {
    networks = {
      hosted = ["database", "ssh_private"]
      linked = []
    }
    install = []
    run = []
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
  },
  ssh_public = {
    all = [
      {
        action = "accept"
        port = 22
        interface = "address"
      } 
    ]
    in = []
    out = []
  },
  ssh_private = {
    all = [
      {
        action = "accept"
        port = 22
        interface = "private"
      } 
    ]
    in = []
    out = []
  },
}