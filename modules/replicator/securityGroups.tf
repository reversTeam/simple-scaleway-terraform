locals {

  pool_networks = flatten([
    for name in keys(var.pools) : {
      name = name
      networks = flatten([ for i in var.infra[name].services : var.services[i].networks.hosted ])
      nodes = var.pools[name]
    }
  ])
  self_networks = flatten([ for i in local.conf.services : var.services[i].networks.hosted ])
  linked_networks = flatten([ for i in local.conf.services : var.services[i].networks.linked ])

  services_all_strict = flatten([
    for pool in local.pool_networks: [
      for network in pool.networks : [
        for node in pool.nodes : [
          for rule in var.networks[network].all : {
            action = rule.action
            port = rule.port
            ip = rule.interface == "address" || rule.interface == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(local.linked_networks, network)
    ]
  ])

  services_inbound_strict = flatten([
    for pool in local.pool_networks: [
      for network in pool.networks : [
        for node in pool.nodes : [
          for rule in var.networks[network].out : {
            action = rule.action
            port = rule.port
            ip = rule.interface == "address" || rule.interface == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(local.linked_networks, network)
    ]
  ])

  services_outbound_strict = flatten([
    for pool in local.pool_networks: [
      for network in pool.networks : [
        for node in pool.nodes : [
          for rule in var.networks[network].in : {
            action = rule.action
            port = rule.port
            ip = rule.interface == "address" || rule.interface == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(local.linked_networks, network)
    ]
  ])

  self_all_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].all : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          port = rule.port
          ip = rule.interface == "address" ? "0.0.0.0/0" : rule.interface == "public" ? instance.public_ip : instance.private_ip
        } if rule.interface != "address" || (rule.interface == "address" && k < 1)
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_inbound_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].out : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          port = rule.port
          ip = rule.interface == "address" ? "0.0.0.0/0" : rule.interface == "public" ? instance.public_ip : instance.private_ip
        } if rule.interface != "address" || (rule.interface == "address" && k < 1) 
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_outbound_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].in : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          port = rule.port
          ip = rule.interface == "address" ? "0.0.0.0/0" : rule.interface == "public" ? instance.public_ip : instance.private_ip
        } if rule.interface != "address" || (rule.interface == "address" && k < 1)
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_inbound = concat(local.self_inbound_strict, local.self_all_strict)
  self_outbound = concat(local.self_outbound_strict, local.self_all_strict)

  services_inbound = concat(local.services_inbound_strict, local.services_all_strict)
  services_outbound = concat(local.services_outbound_strict, local.services_all_strict)
}

resource "scaleway_security_group_rule" "self_inbound" {
  count = length(local.self_inbound)
  security_group = scaleway_security_group.security_group.id

  action    = local.self_inbound[count.index].action
  direction = "inbound"
  ip_range  = local.self_inbound[count.index].ip
  protocol  = "TCP"
  port      = local.self_inbound[count.index].port
}

resource "scaleway_security_group_rule" "self_outbound" {
  count = length(local.self_outbound)
  security_group = scaleway_security_group.security_group.id

  action    = local.self_outbound[count.index].action
  direction = "outbound"
  ip_range  = local.self_outbound[count.index].ip
  protocol  = "TCP"
  port      = local.self_outbound[count.index].port
}

resource "scaleway_security_group_rule" "services_outbound" {
  count = length(local.services_outbound)
  security_group = scaleway_security_group.security_group.id

  action    = local.services_outbound[count.index].action
  direction = "outbound"
  ip_range  = local.services_outbound[count.index].ip
  protocol  = "TCP"
  port      = local.services_outbound[count.index].port
}

resource "scaleway_security_group_rule" "services_inbound" {
  count = length(local.services_inbound)
  security_group = scaleway_security_group.security_group.id

  action    = local.services_inbound[count.index].action
  direction = "inbound"
  ip_range  = local.services_inbound[count.index].ip
  protocol  = "TCP"
  port      = local.services_inbound[count.index].port
}

