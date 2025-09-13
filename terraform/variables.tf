variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "zone" {
  type    = string
  default = "us-central1-a"
}

variable "instance_name" {
  type    = string
  default = "devops-free-dev"
}

variable "machine_type" {
  type    = string
  default = "e2-micro"
}

variable "ssh_pub_key" {
  type    = string
  default = "~/.ssh/id_rsa.pub"
}
