output "public_ip" {
  description = "VM external IPv4"
  value       = google_compute_instance.dev.network_interface[0].access_config[0].nat_ip
}
