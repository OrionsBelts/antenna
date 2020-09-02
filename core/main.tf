terraform {
  required_version = ">= 0.12"
}

provider "digitalocean" {
  token = var.do_token
}

# - Variables
variable "do_create_record" {
  default     = true
  description = "Whether to create a DNS record on Digitalocean"
}
variable "do_domain" {
  description = "Your public domain"
}
variable "do_ipv4_float" {
  description = "Floating IP to attach to droplet."
}
variable "do_ssh_key" {
  description = "Digitalocean sshkey in your account."
}
variable "do_region" {
  default     = "nyc2"
  description = "The Digitalocean region where the faasd droplet will be created."
}
variable "do_registry_auth" {
  description = "Digitalocean auth for their container registry."
}
variable "do_subdomain" {
  description = "Your public subdomain"
}
variable "do_token" {
  description = "Digitalocean API token"
}
variable "letsencrypt_email" {
  description = "Email used to order a certificate from Letsencrypt"
}
variable "ssh_key_file" {
  description = "Path to the SSH public key file"
}

# - Data Sources
data "digitalocean_droplet" "vpn" {
  name = "barnards-loop"
}
data "digitalocean_floating_ip" "nyc2-ipv4-address" {
  ip_address = var.do_ipv4_float
}
data "digitalocean_ssh_key" "main" {
  name = var.do_ssh_key
}
data "local_file" "ssh_key" {
  filename = pathexpand(var.ssh_key_file)
}
data "template_file" "cloud_init" {
  template = "${file("cloud-config.tpl")}"
  vars = {
    gw_password       = random_password.password.result,
    ssh_key           = data.local_file.ssh_key.content,
    do_registry_auth  = var.do_registry_auth,
    faasd_domain_name = "${var.do_subdomain}.${var.do_domain}"
    letsencrypt_email = var.letsencrypt_email
  }
}

# - Resource Definitions
resource "digitalocean_droplet" "faasd" {
  image              = "ubuntu-18-04-x64"
  name               = "faasd.${var.do_subdomain}"
  private_networking = true
  region             = var.do_region
  size               = "s-1vcpu-1gb"
  ssh_keys           = [data.digitalocean_ssh_key.main.id]
  user_data          = data.template_file.cloud_init.rendered
}

resource "digitalocean_firewall" "faasd" {
  droplet_ids = [digitalocean_droplet.faasd.id]
  name        = "open-web-default-ssh"

  # SSH rules
  inbound_rule {
    protocol           = "tcp"
    port_range         = "22"
    source_droplet_ids = [data.digitalocean_droplet.vpn.id]
  }

  # Inbound Rules
  # HTTP/HTTPS rules
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  # Outbound Rules
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}

resource "digitalocean_floating_ip_assignment" "faasd-ipv4" {
  ip_address = var.do_ipv4_float
  droplet_id = digitalocean_droplet.faasd.id
}

resource "digitalocean_record" "faasd" {
  domain = var.do_domain
  type   = "A"
  name   = var.do_subdomain
  value  = var.do_ipv4_float
  # Only creates record if do_create_record is true
  count = var.do_create_record == true ? 1 : 0
}

resource "random_password" "password" {
  length           = 45
  special          = true
  override_special = "_-#"
}

# - Output Variables
output "droplet_ip" {
  value = digitalocean_droplet.faasd.ipv4_address
}

output "gateway_url" {
  value = "https://${var.do_subdomain}.${var.do_domain}/"
}

output "password" {
  value = random_password.password.result
}

output "login_cmd" {
  value = "faas-cli login -g https://${var.do_subdomain}.${var.do_domain}/ -p ${random_password.password.result}"
}
