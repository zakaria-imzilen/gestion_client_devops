terraform {
  required_version = ">= 1.5.0"
  required_providers { google = { source = "hashicorp/google", version = ">= 5.30.0" } }
}

provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.zone
}

data "google_compute_network" "default" { name = "default" }

# Firewall opens all ports required by AC (even if you use SaaS later)
resource "google_compute_firewall" "devops_fw" {
  name    = "${var.instance_name}-fw"
  network = data.google_compute_network.default.self_link
  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]        # tighten to your IP after demo
  allow {
    protocol = "tcp"
    ports    = ["22","8080","8081","9000","3000","9090"]
  }
  target_tags = ["devops-free"]
}

# VM definition (matches what you created in the console)
resource "google_compute_instance" "dev" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["devops-free"]

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
      size  = 20
    }
  }

  network_interface {
    network = data.google_compute_network.default.self_link
    access_config {}
  }

  metadata = {
    "ssh-keys" = "ubuntu:${chomp(file(pathexpand(var.ssh_pub_key)))}"
  }
}
