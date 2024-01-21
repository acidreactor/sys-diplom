# create network
resource "yandex_vpc_network" "network" {
  name = "network"
}

# create private subnet-1
resource "yandex_vpc_subnet" "private-subnet-1" {
  name           = "private-subnet-1"
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.1.0/24"]
  description    = "subnet for webserver-1"
}

# create private subnet-2
resource "yandex_vpc_subnet" "private-subnet-2" {
  name           = "private-subnet-2"
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.2.0/24"]
  description    = "subnet for webserver-2"
}

#create private subnet-3
resource "yandex_vpc_subnet" "private-subnet-3" {
  name           = "private-subnet-3"
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network.id
  route_table_id = yandex_vpc_route_table.route_table.id
  v4_cidr_blocks = ["192.168.3.0/24"]
  description    = "subnet for elasticsearch"

}

# create webserver-1
resource "yandex_compute_instance" "vm-1" {
  name                      = "wm-1"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  hostname                  = "webserver-1"
  zone                      = "ru-central1-a"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-1.id
    security_group_ids = [yandex_vpc_security_group.private-security-group.id]
    ip_address         = "192.168.1.10"
    #nat       = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }
  scheduling_policy {
    preemptible = true
  }
}


# create webserver-2
resource "yandex_compute_instance" "vm-2" {
  name                      = "wm-2"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  hostname                  = "webserver-2"
  zone                      = "ru-central1-b"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      size     = 8
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-2.id
    security_group_ids = [yandex_vpc_security_group.private-security-group.id]
    ip_address         = "192.168.2.10"
    #nat       = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }

  scheduling_policy {
    preemptible = true
  }
}

#create wm for zabbix-server
resource "yandex_compute_instance" "zabbix-server" {
  name                      = "zabbix-server"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  hostname                  = "zabbix-server"
  zone                      = "ru-central1-c"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      size     = 15
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.private-security-group.id, yandex_vpc_security_group.zabbix-security-group.id]
    ip_address         = "192.168.4.10"
    nat                = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }
  scheduling_policy {
    preemptible = true
  }
}

# create target-group

resource "yandex_alb_target_group" "target-group" {
  name = "target-group"

  target {
    subnet_id  = yandex_vpc_subnet.private-subnet-1.id
    ip_address = yandex_compute_instance.vm-1.network_interface.0.ip_address
  }

  target {
    subnet_id  = yandex_vpc_subnet.private-subnet-2.id
    ip_address = yandex_compute_instance.vm-2.network_interface.0.ip_address
  }
}

# create backend-group

resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"

  http_backend {
    name             = "backend-group"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.target-group.id}"]

    load_balancing_config {
      panic_threshold = 10
    }
    healthcheck {
      timeout  = "1s"
      interval = "1s"
      #  healthy_threshold   = 2
      #  unhealthy_threshold = 2
      http_healthcheck {
        path = "/"
      }
    }
  }
}


# create http-router
resource "yandex_alb_http_router" "http-router" {
  name = "http-router"
}

# create virtual host
resource "yandex_alb_virtual_host" "virtual-host" {
  name           = "virtual-host"
  http_router_id = yandex_alb_http_router.http-router.id
  route {
    name = "route"

    http_route {
      http_route_action {
        backend_group_id = yandex_alb_backend_group.backend-group.id
        timeout          = "3s"
      }
    }
  }
}


# create load balancer

resource "yandex_alb_load_balancer" "balancer" {
  name = "balancer"

  network_id         = yandex_vpc_network.network.id
  security_group_ids = [yandex_vpc_security_group.load-balancer-security-group.id, yandex_vpc_security_group.private-security-group.id]

  allocation_policy {
    location {
      zone_id   = "ru-central1-a"
      subnet_id = yandex_vpc_subnet.private-subnet-1.id
    }

    location {
      zone_id   = "ru-central1-b"
      subnet_id = yandex_vpc_subnet.private-subnet-2.id
    }
  }

  listener {
    name = "listener"
    endpoint {
      address {
        external_ipv4_address {
        }
      }
      ports = [80]
    }
    http {
      handler {
        http_router_id = yandex_alb_http_router.http-router.id
      }
    }
  }
}


#create wm for elasticsearch
resource "yandex_compute_instance" "elasticsearch" {
  name                      = "elasticsearch"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"
  hostname                  = "elasticsearch"
  zone                      = "ru-central1-c"

  resources {
    cores         = 4
    memory        = 8
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      size     = 12
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.private-subnet-3.id
    security_group_ids = [yandex_vpc_security_group.private-security-group.id, yandex_vpc_security_group.elasticsearch-security-group.id]
    ip_address         = "192.168.3.10"
    #nat                = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }
  scheduling_policy {
    preemptible = true
  }
}

# create wm for kibana
resource "yandex_compute_instance" "kibana" {
  name                      = "kibana"
  hostname                  = "kibana"
  zone                      = "ru-central1-c"
  allow_stopping_for_update = true
  platform_id               = "standard-v1"

  resources {
    cores         = 2
    memory        = 2
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      size     = 8
    }
  }
  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.private-security-group.id, yandex_vpc_security_group.kibana-security-group.id]
    ip_address         = "192.168.4.200"
    nat                = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }
  scheduling_policy {
    preemptible = true
  }
}
# NAT route table
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "nat-gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.network.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}

# security group
resource "yandex_vpc_security_group" "private-security-group" {
  name       = "private-security-group"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol = "TCP"

    predefined_target = "loadbalancer_healthchecks"
    from_port         = 0
    to_port           = 65535
  }

  ingress {
    protocol       = "ANY"
    v4_cidr_blocks = ["192.168.1.0/24", "192.168.2.0/24", "192.168.3.0/24", "192.168.4.0/24"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "load-balancer-security-group" {
  name       = "load-balancer-security-group"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol          = "ANY"
    v4_cidr_blocks    = ["0.0.0.0/0"]
    predefined_target = "loadbalancer_healthchecks"
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "bastion-security-group" {
  name       = "bastion-security-group"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}



resource "yandex_vpc_security_group" "kibana-security-group" {
  name       = "kibana-security-group"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "zabbix-security-group" {
  name       = "zabbix-security-group"
  network_id = yandex_vpc_network.network.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "ICMP"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "yandex_vpc_security_group" "elasticsearch-security-group" {
  name        = "elasticsearch-security-group"
  description = "elasticsearch security group"
  network_id  = yandex_vpc_network.network.id

  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.kibana-security-group.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "rule for web"
    security_group_id = yandex_vpc_security_group.private-security-group.id
    port              = 9200
  }

  ingress {
    protocol          = "TCP"
    description       = "rule for bastion ssh"
    security_group_id = yandex_vpc_security_group.bastion-security-group.id
    port              = 22
  }

  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

# bastion
resource "yandex_vpc_subnet" "public-subnet" {
  name = "public-subnet"

  v4_cidr_blocks = ["192.168.4.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network.id
}

resource "yandex_compute_instance" "bastion" {
  name     = "bastion"
  hostname = "bastion"
  zone     = "ru-central1-c"

  resources {
    cores         = 2
    memory        = 4
    core_fraction = 20
  }

  boot_disk {
    initialize_params {
      image_id = "fd8dibo9ts96rt2ihbsm"
      # type     = "network-ssd"
      size = 16
    }
  }

  network_interface {
    subnet_id          = yandex_vpc_subnet.public-subnet.id
    security_group_ids = [yandex_vpc_security_group.bastion-security-group.id]
    ip_address         = "192.168.4.100"
    nat                = true
  }

  metadata = {
    user-data = file("./meta.yaml")
  }

  scheduling_policy {
    preemptible = true
  }

}

resource "yandex_compute_snapshot_schedule" "snapshot" {
  name        = "snapshot"
  description = "everyday"

  schedule_policy {
    expression = "0 4 * * *"
  }

  retention_period = "168h"
  snapshot_count   = "6"

  disk_ids = [
    "${yandex_compute_instance.vm-1.boot_disk[0].disk_id}",
    "${yandex_compute_instance.vm-2.boot_disk[0].disk_id}",
    "${yandex_compute_instance.zabbix-server.boot_disk[0].disk_id}",
    "${yandex_compute_instance.elasticsearch.boot_disk[0].disk_id}",
    "${yandex_compute_instance.kibana.boot_disk[0].disk_id}",
    "${yandex_compute_instance.bastion.boot_disk[0].disk_id}"
  ]
}
