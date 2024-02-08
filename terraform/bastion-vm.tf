resource "yandex_compute_instance" "bastion-vm" {
  name     = "bastion-vm"
  hostname = "bastion-vm"
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
    security_group_ids = [yandex_vpc_security_group.ssh-access.id, yandex_vpc_security_group.ssh-access-local.id]
    ip_address         = "10.4.1.40"
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