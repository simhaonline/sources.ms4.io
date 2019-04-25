resource "scaleway_ip" "worker2_ip" {
}

resource "scaleway_server" "worker2" {
  name       = "worker2"
  public_ip  = "scaleway_ip.worker2_ip.id}"
  image      = "${data.scaleway_image.ubuntu.id}"
  type       = "START1-M"
  tags = [
    "node"
  ]

  connection {
    type     = "ssh"
    private_key = "${file("~/.ssh/id_rsa")}"
    user     = "root"
    timeout  = "2m"
  }

  provisioner "file" {
    source      = "${path.module}/hack/bootstrap.sh"
    destination = "/root/bootstrap.sh"
  }

  provisioner "remote-exec" {
    inline = "/bin/bash /root/bootstrap.sh"
  }
  provisioner "remote-exec" {
    inline = [
      "useradd -m -G docker rke",
      "echo -e \"1q2w3e4r*\n1q2w3e4r*\" | passwd rke",
      "echo -e \"1q2w3e4r*\n1q2w3e4r*\" | sudo passwd root",
      "sudo mkdir -p /home/rke/.ssh",
      "sudo touch /home/rke/.ssh/authorized_keys",
      "sudo cat /root/.ssh/authorized_keys >> /home/rke/.ssh/authorized_keys",
      "sudo chown -R rke:rke /home/rke/.ssh",
      "sudo chmod 700 /home/rke/.ssh",
      "sudo chmod 600 /home/rke/.ssh/authorized_keys",
      "sudo usermod -aG sudo rke"
    ]

  }
}

resource "cloudflare_record" "worker2dnsname" {
  domain = "ms4.io"
  type   = "A"
  name   = "worker2"
  value  = "${scaleway_server.worker2.public_ip}"
}