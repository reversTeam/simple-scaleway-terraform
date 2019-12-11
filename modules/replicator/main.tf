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

resource "scaleway_security_group" "security_group" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}"
  description = "Allow all network configuration for ${var.cluster}"
  inbound_default_policy  = "accept"
  outbound_default_policy = "accept"
}

resource "scaleway_instance_server" "instances" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}n${count.index + 1}"
  count = local.conf.scale
  type = local.conf.type
  image = local.conf.image

  tags = []

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.keypath)
    host        = self.public_ip
  }

  # install command
  provisioner "remote-exec" {
    inline = [
      "rm /var/lib/apt/lists/lock",
      "apt-get update"
    ]
  }

  # install command
  provisioner "remote-exec" {
    inline = local.install_command
  }

  # run command
  provisioner "remote-exec" {
    inline = local.run_command
  }

  security_group_id = scaleway_security_group.security_group.id
}

output "address" {
  value = scaleway_instance_ip.ip.*.address
}

output "nodes" {
  value = scaleway_instance_server.instances
}