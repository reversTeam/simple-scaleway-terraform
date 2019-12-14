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
    public_ip = false
    image = "1ec3f179-5b05-408f-a8b3-344e4d8d22d9"
    type = "DEV1-S"
    services = [ "wordpress" ]
  },
  database = {
    scale = 1
    public_ip = true
    image = "1ec3f179-5b05-408f-a8b3-344e4d8d22d9"
    type = "DEV1-S"
    services = [ "mysql" ]
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
      "apt install libapache2-mod-php",
      "apt-get install php7.2-mysql",
      "service apache2 restart",

    ]
    run = []
  }
  mysql = {
    networks = {
      hosted = ["database"]
      linked = []
    }
    install = [
      "apt-get update && apt-get upgrade -y",
      "echo 'Europe/Paris' > /etc/timezone",
      "echo 'mysql-server-5.6 mysql-server/root_password password root' | debconf-set-selections",
      "echo 'mysql-server-5.6 mysql-server/root_password_again password root' | debconf-set-selections",
      "apt-get -y install mysql-server",
      "mysql_secure_installation",
      "sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mysql/mysql.conf.d/mysqld.cnf",
      "mysql -uroot -proot -e 'USE mysql; UPDATE `user` SET `Host`=\"%\" WHERE `User`=\"root\" AND `Host`=\"localhost\"; DELETE FROM `user` WHERE `Host` != \"%\" AND `User`=\"root\"; FLUSH PRIVILEGES;'",
      "service mysql restart",
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
        port = 3306
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