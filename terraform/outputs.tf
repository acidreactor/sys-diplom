output "zabbix-server" {
  value = yandex_compute_instance.zabbix-server.network_interface.0.nat_ip_address
}

output "site" {
  value = yandex_alb_load_balancer.balancer.listener.0.endpoint.0.address.0.external_ipv4_address.0.address
}

output "bastion-host" {
  value = yandex_compute_instance.bastion.network_interface.0.nat_ip_address
}

output "kibana" {
  value = yandex_compute_instance.kibana.network_interface.0.nat_ip_address
}




