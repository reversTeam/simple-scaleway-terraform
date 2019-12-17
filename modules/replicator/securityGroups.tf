locals {
  pool_networks = flatten([
    for name in keys(var.pools) : {
      name = name
      hosted = flatten([ for i in var.infra[name].services : var.services[i].networks.hosted ])
      linked = flatten([ for i in var.infra[name].services : var.services[i].networks.linked ])
      nodes = var.pools[name]
    } if name != var.module_name
  ])
  self_networks = concat(
    var.common_networks,
    flatten([ for i in local.conf.services : var.services[i].networks.hosted ])
  )
  linked_networks = flatten([ for i in local.conf.services : var.services[i].networks.linked ])
  hosted_networks = flatten([ for i in local.conf.services : var.services[i].networks.hosted ])


  services_hosted_all_strict = flatten([
    for network in local.hosted_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].all : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(pool.linked, network)
    ]
  ])

  services_hosted_inbound_strict = flatten([
    for network in local.hosted_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].out : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(pool.linked, network)
    ]
  ])

  services_hosted_outbound_strict = flatten([
    for network in local.hosted_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].in : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : node.private_ip
          }
        ]
      ] if contains(pool.linked, network)
    ]
  ])

  services_linked_all_strict = flatten([
    for network in local.linked_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].all : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : rule.ip == "private" ? node.private_ip : rule.ip
          }
        ]
      ] if contains(pool.hosted, network)
    ]
  ])

  services_linked_inbound_strict = flatten([
    for network in local.linked_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].out : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : rule.ip == "private" ? node.private_ip : rule.ip
          }
        ]
      ] if contains(pool.hosted, network)
    ]
  ])

  services_linked_outbound_strict = flatten([
    for network in local.linked_networks: [
      for pool in local.pool_networks: [
        for node in pool.nodes : [
          for rule in var.networks[network].in : {
            action = rule.action
            protocol = rule.protocol
            port = rule.port
            ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? node.public_ip : rule.ip == "private" ? node.private_ip : rule.ip
          }
        ]
      ] if contains(pool.hosted, network)
    ]
  ])

  self_all_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].all : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          protocol = rule.protocol
          port = rule.port
          ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? instance.public_ip : rule.ip == "private" ? instance.private_ip : rule.ip
        } if rule.ip != "address" || (rule.ip == "address" && k == 0)
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_inbound_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].in : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          protocol = rule.protocol
          port = rule.port
          ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? instance.public_ip : rule.ip == "private" ? instance.private_ip : rule.ip
        } if rule.ip != "address" || (rule.ip == "address" && k == 0) 
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_outbound_strict = flatten([
    for network in local.self_networks : [
      for rule in var.networks[network].out : [
        for k, instance in scaleway_instance_server.instances : {
          action = rule.action
          protocol = rule.protocol
          port = rule.port
          ip = rule.ip == "address" ? "0.0.0.0/0" : rule.ip == "public" ? instance.public_ip : rule.ip == "private" ? instance.private_ip : rule.ip
        } if rule.ip != "address" || (rule.ip == "address" && k == 0)
      ]
    ] if contains(keys(var.networks), network)
  ])

  self_inbound = concat(local.self_inbound_strict, local.self_all_strict)
  self_outbound = concat(local.self_outbound_strict, local.self_all_strict)

  services_inbound = concat(
    local.services_hosted_inbound_strict,
    local.services_hosted_all_strict,
    local.services_linked_inbound_strict,
    local.services_linked_all_strict
  )
  services_outbound = concat(
    local.services_hosted_outbound_strict,
    local.services_hosted_all_strict,
    local.services_linked_outbound_strict,
    local.services_linked_all_strict
  )
}

resource "scaleway_security_group_rule" "self_inbound" {
  count = length(local.self_inbound)
  security_group = scaleway_security_group.run.id

  action    = local.self_inbound[count.index].action
  direction = "inbound"
  ip_range  = local.self_inbound[count.index].ip
  protocol  = local.self_inbound[count.index].protocol
  port      = local.self_inbound[count.index].port
}

resource "scaleway_security_group_rule" "self_outbound" {
  count = length(local.self_outbound)
  security_group = scaleway_security_group.run.id

  action    = local.self_outbound[count.index].action
  direction = "outbound"
  ip_range  = local.self_outbound[count.index].ip
  protocol  = local.self_outbound[count.index].protocol
  port      = local.self_outbound[count.index].port
}

resource "scaleway_security_group_rule" "services_outbound" {
  count = length(local.services_outbound)
  security_group = scaleway_security_group.run.id

  action    = local.services_outbound[count.index].action
  direction = "outbound"
  ip_range  = local.services_outbound[count.index].ip
  protocol  = local.services_outbound[count.index].protocol
  port      = local.services_outbound[count.index].port
}

resource "scaleway_security_group_rule" "services_inbound" {
  count = length(local.services_inbound)
  security_group = scaleway_security_group.run.id

  action    = local.services_inbound[count.index].action
  direction = "inbound"
  ip_range  = local.services_inbound[count.index].ip
  protocol  = local.services_inbound[count.index].protocol
  port      = local.services_inbound[count.index].port
}


output "self_inbound" {
  value = scaleway_security_group_rule.self_inbound.*
}

output "self_outbound" {
  value = scaleway_security_group_rule.self_outbound.*
}

output "services_outbound" {
  value = scaleway_security_group_rule.services_outbound.*
}

output "services_inbound" {
  value = scaleway_security_group_rule.services_inbound.*
}