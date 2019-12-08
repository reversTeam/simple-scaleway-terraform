resource "scaleway_instance_ip" "ip" {
  count = var.conf.public_ip ? var.conf.scale : 0
  server_id = scaleway_instance_server.instances[count.index].id
}

resource "scaleway_security_group" "security_group" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}"
  description = "Allow all network configuration for ${var.cluster}"
  inbound_default_policy  = "drop"
  outbound_default_policy = "drop"
}

resource "scaleway_instance_server" "instances" {
  name = "${var.project}-${var.module_name}-${var.region}-c${var.cluster}n${count.index + 1}"
  count = var.conf.scale
  type = var.conf.type
  image = var.conf.image

  tags = []

  connection {
    type        = "ssh"
    user        = "root"
    private_key = file(var.keypath)
    host        = self.public_ip
  }

  security_group_id= scaleway_security_group.security_group.id
}

output "address" {
  value = scaleway_instance_ip.ip.*.address
}

output "nodes" {
  value = scaleway_instance_server.instances
}