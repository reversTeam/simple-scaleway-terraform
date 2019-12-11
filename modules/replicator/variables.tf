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

variable "pools" {}