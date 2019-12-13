locals {
  conf = var.infra[var.module_name]
  install_command = flatten([
    for service in local.conf.services : [
      var.services[service].install
    ]
  ])
  run_command = flatten([
    for service in local.conf.services : [
      var.services[service].run
    ]
  ])
}

resource "scaleway_instance_ip" "ip" {
  count = local.conf.public_ip ? local.conf.scale : 0
  server_id = scaleway_instance_server.instances[count.index].id
}

resource "scaleway_security_group" "run" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}"
  description = "Allow all network configuration for c${var.cluster}"
  inbound_default_policy  = "drop"
  outbound_default_policy = "drop"
  stateful = true
}

resource "scaleway_instance_server" "instances" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}n${count.index + 1}"
  count = local.conf.scale
  type = local.conf.type
  image = local.conf.image

  tags = []

  security_group_id = scaleway_security_group.run.id
}

resource "null_resource" "install" {
  count = local.conf.scale
  depends_on = [scaleway_security_group_rule.self_inbound]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.keypath)
    host        = local.conf.public_ip ? scaleway_instance_ip.ip[count.index].address : scaleway_instance_server.instances[count.index].public_ip
  }

  # install command
  provisioner "remote-exec" {
    inline = concat(
      [ "apt-get update" ],
      local.install_command
    )
  }

}

resource "null_resource" "run" {
  count = local.conf.scale
  depends_on = [null_resource.install]
  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.keypath)
    host        = local.conf.public_ip ? scaleway_instance_ip.ip[count.index].address : scaleway_instance_server.instances[count.index].public_ip
  }
  # run command
  provisioner "remote-exec" {
    inline = local.run_command
  }
}


output "address" {
  value = scaleway_instance_ip.ip.*.address
}

output "nodes" {
  value = scaleway_instance_server.instances
}