#web-1
output "webserver-1" {
  value = yandex_compute_instance.web-vm-1.network_interface.0.ip_address
}

#web-2
output "webserver-2" {
  value = yandex_compute_instance.web-vm-2.network_interface.0.ip_address
}

#load_balancer
output "load_balancer_pub" {
  value = yandex_alb_load_balancer.load-balancer.listener[0].endpoint[0].address[0].external_ipv4_address
}

#bastion
output "bastion_nat" {
  value = yandex_compute_instance.bastion-vm.network_interface.0.nat_ip_address
}
output "bastion" {
  value = yandex_compute_instance.bastion-vm.network_interface.0.ip_address
}

#kibana
output "kibana-nat" {
  value = yandex_compute_instance.kibana-vm.network_interface.0.nat_ip_address
}
output "kibana" {
  value = yandex_compute_instance.kibana-vm.network_interface.0.ip_address
}

#zabbix
output "zabbix_nat" {
  value = yandex_compute_instance.zabbix-vm.network_interface.0.nat_ip_address
}
output "zabbix" {
  value = yandex_compute_instance.zabbix-vm.network_interface.0.ip_address
}

#elasticsearch
output "elasticsearch-vm" {
  value = yandex_compute_instance.elasticsearch-vm.network_interface.0.ip_address
}