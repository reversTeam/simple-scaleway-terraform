provider "scaleway" {
  access_key = var.scw_api_key
  secret_key = var.scw_secret_key
  organization_id = var.scw_org_id 
  zone       = var.scw_zone
  region     = var.scw_region
  version = "~> 1.11"
}

module "database" {
  source = "./modules/replicator"
  module_name = "database"
  project = var.project
  cluster = var.cluster
  region = var.scw_region

  infra = var.infra
  services = var.services
  networks = var.networks
  keypath = var.keypath

  common_networks = var.common_networks

  pools = {
    web = module.web.nodes
    proxy = module.database.nodes
  }
}

module "proxy" {
  source = "./modules/replicator"
  module_name = "proxy"
  project = var.project
  cluster = var.cluster
  region = var.scw_region

  infra = var.infra
  services = var.services
  networks = var.networks
  keypath = var.keypath

  common_networks = var.common_networks

  pools = {
    web = module.web.nodes
    database = module.database.nodes
  }
}

module "web" {
  source = "./modules/replicator"
  module_name = "web"
  project = var.project
  cluster = var.cluster
  region = var.scw_region

  infra = var.infra
  services = var.services
  networks = var.networks
  keypath = var.keypath

  common_networks = var.common_networks

  pools = {
    database = module.database.nodes
    proxy = module.proxy.nodes
  }
}