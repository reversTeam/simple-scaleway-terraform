variable "scw_api_key" {
  type = string
}
variable "scw_secret_key" {
  type = string
}
variable "scw_org_id" {
  type = string
}
variable "scw_zone" {
  type = string
  default = "fr-par-1"
}
variable "scw_region" {
  type = string
  default = "fr-par"
}
variable "cluster" {
  type = number
  default = 1
}
variable "project" {
  type = string
  default = "ffs"
}
variable "keypath" {
  type = string
  default = "~/.ssh/deployment"
}

variable "infra" {
  type = map(object({
    scale = number
    image = string
    type = string
    services = list(string)
    public_ip = bool
  }))
}

variable "services" {
  type = map(object({
    networks = object({
      hosted = list(string)
      linked = list(string)
    })
    install = list(string)
    run = list(string)
  }))
}

variable "networks" {
  type = map(object({
    all = list(object({
      action = string
      port = number
      interface = string
    }))
    in = list(object({
      action = string
      port = number
      interface = string
    }))
    out = list(object({
      action = string
      port = number
      interface = string
    }))
  }))
}