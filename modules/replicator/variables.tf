variable "module_name" {
  type = string
}

variable "cluster" {
  type = number
  default = 1
}

variable "region" {
  type = string
  default = "fr-par"
}

variable "project" {
  type = string
  default = "default"
}

variable "keypath" {
  type = string
  default = "~/.ssh/deployment"
}

variable "common_networks" {
  type = list(string)
  default = []
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
      protocol = string
      ip = string
    }))
    in = list(object({
      action = string
      port = number
      protocol = string
      ip = string
    }))
    out = list(object({
      action = string
      port = number
      protocol = string
      ip = string
    }))
  }))
}

variable "pools" {}