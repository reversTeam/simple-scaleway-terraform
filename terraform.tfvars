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

# common networks for simplify install process and other
# the three networks it's required for run remote cmd and apt-get update
common_networks = ["ssh_public", "dns", "public"]

# define your infrastructure
infra = {
  proxy = {
    scale = 1
    public_ip = true
    image = "1ec3f179-5b05-408f-a8b3-344e4d8d22d9"
    type = "DEV1-S"
    services = [ "nginx" ]
  },
  web = {
    scale = 1
    public_ip = true
    image = "1ec3f179-5b05-408f-a8b3-344e4d8d22d9"
    type = "DEV1-S"
    services = [ "wordpress" ]
  },
  database = {
    scale = 1
    public_ip = true
    image = "1ec3f179-5b05-408f-a8b3-344e4d8d22d9"
    type = "DEV1-S"
    services = [ "psql" ]
  },
}

## define the networks link services 
services = {
  nginx = {
    networks = {
      hosted = ["public"]
      linked = ["web"]
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
      hosted = ["web"]
      linked = ["database"]
    }
    install = [
      "apt install -y apache2",
      "wget https://codeload.github.com/WordPress/WordPress/zip/master",
      "unzip master",
      "rm -rf /var/www/html",
      "mv WordPress-master /var/www/html",
      "sed -i 's/Listen 80/Listen 0.0.0.0:8080/g' /etc/apache2/ports.conf",
      "sed -i 's/:80/:8080/g' /etc/apache2/sites-available/000-default.conf",
      "service apache2 restart",

    ]
    run = []
  }
  psql = {
    networks = {
      hosted = ["database"]
      linked = []
    }
    install = [
      "export DEBIAN_FRONTEND=noninteractive",
      "apt install -y postgresql",
      "su - postgres -c \"psql -U postgres -d postgres -c \\\"alter user postgres with password 'YouNeedToModifiedThatPassword';\\\"\"",
      "echo 'host    all             all             0.0.0.0/0               md5' >> /etc/postgresql/10/main/pg_hba.conf",
      "echo \"listen_addresses = '0.0.0.0'\" >> /etc/postgresql/10/main/postgresql.conf",
      "/etc/init.d/postgresql restart",
    ]
    run = []
  }

}

## define each network
networks = {
  dns = {
    all = [
      {
        action = "accept"
        port = 53
        protocol = "TCP"
        interface = "address"
      },
      {
        action = "accept"
        port = 53
        protocol = "UDP"
        interface = "address"
      }
    ]
    in = []
    out = []
  }
  public = {
    all = [
      {
        action = "accept"
        port = 80
        protocol = "TCP"
        interface = "address"
      },
      {
        action = "accept"
        port = 443
        protocol = "TCP"
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
        protocol = "TCP"
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
        protocol = "TCP"
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
        protocol = "TCP"
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
        protocol = "TCP"
        interface = "private"
      } 
    ]
    in = []
    out = []
  },
}