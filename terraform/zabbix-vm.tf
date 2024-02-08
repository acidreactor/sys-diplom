resource "yandex_compute_instance" "zabbix-vm" {
  name     = "zabbix-vm"
  hostname = "zabbix-vm"
  zone     = "ru-central1-c"

  resources {
    cores         = 4
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8vljd295nqdaoogf3g"
      type     = "network-hdd"
      size     = "10"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-3.id
    security_group_ids = [yandex_vpc_security_group.ssh-access-local.id, yandex_vpc_security_group.zabbix-sg.id]
    ip_address         = "10.3.1.30"
    nat                = true
  }

  timeouts {
    create = "10m"
  }

  metadata = {
    user-data = "${file("./meta.yml")}"
  }

  #scheduling_policy {
  #  preemptible = true
  #}
}