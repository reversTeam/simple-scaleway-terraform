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

  conf = var.infra.database
  services = var.services
  networks = var.networks

  ips = {
    web = module.web.nodes
  }
}

module "proxy" {
  source = "./modules/replicator"
  module_name = "proxy"
  project = var.project
  cluster = var.cluster
  region = var.scw_region

  conf = var.infra.proxy
  services = var.services
  networks = var.networks

  ips = {
    web = module.web.nodes
  }
}

module "web" {
  source = "./modules/replicator"
  module_name = "web"
  project = var.project
  cluster = var.cluster
  region = var.scw_region

  conf = var.infra.web
  services = var.services
  networks = var.networks


  ips = {}
}