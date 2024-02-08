resource "yandex_compute_instance" "elasticsearch-vm" {
  name     = "elasticsearch-vm"
  hostname = "elasticsearch-vm"
  zone     = "ru-central1-c"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      type     = "network-hdd"
      size     = "10"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-3.id
    security_group_ids = [yandex_vpc_security_group.ssh-access-local.id, yandex_vpc_security_group.elasticsearch-sg.id, yandex_vpc_security_group.kibana-sg.id, yandex_vpc_security_group.filebeat-sg.id]
    ip_address         = "10.3.1.33"
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

resource "yandex_compute_instance" "kibana-vm" {
  name     = "kibana-vm"
  hostname = "kibana-vm"
  zone     = "ru-central1-c"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = var.image_id
      type     = "network-hdd"
      size     = "10"
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.ssh-access-local.id, yandex_vpc_security_group.kibana-sg.id, yandex_vpc_security_group.elasticsearch-sg.id, yandex_vpc_security_group.filebeat-sg.id]
    ip_address         = "10.4.1.7"
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