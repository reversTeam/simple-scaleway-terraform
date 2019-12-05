# scw region
scw_region = "fr-par"

# scw zone
scw_zone = "fr-par-1"

# project name
project = "default"

# cluster id
cluster = 1

# define your infrastructure
infra = {
  proxy = {
    scale = 1
    public_ip = true
    image = "16adb3bb-3ec0-464a-b265-9b6234e483ca"
    type = "DEV1-S"
    services = [ "nginx" ]
  },
  web = {
    scale = 1
    public_ip = false
    image = "16adb3bb-3ec0-464a-b265-9b6234e483ca"
    type = "DEV1-S"
    services = [ "wordpress" ] 
  },
  database = {
    scale = 1
    public_ip = false
    image = "16adb3bb-3ec0-464a-b265-9b6234e483ca"
    type = "DEV1-S"
    services = [ "psql" ]
  },
}

## define the networks link services 
services = {
  nginx = {
    networks = ["public",  "web"]
  }
  wordpress = {
    networks = ["web", "database"]
  }
  psql = {
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