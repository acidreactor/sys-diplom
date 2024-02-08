#target group для балансировщика из двух сайтов с nginx
resource "yandex_alb_target_group" "tg-group" {
  name = "tg-group"

  target {
    ip_address = yandex_compute_instance.web-vm-1.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private-1.id
  }

  target {
    ip_address = yandex_compute_instance.web-vm-2.network_interface.0.ip_address
    subnet_id  = yandex_vpc_subnet.private-2.id
  }

  /*depends_on = [
    yandex_compute_instance.web-vm-1,
    yandex_compute_instance.web-vm-2,
  ]*/
}

#backend Group
resource "yandex_alb_backend_group" "backend-group" {
  name = "backend-group"

  http_backend {
    name             = "backend"
    weight           = 1
    port             = 80
    target_group_ids = ["${yandex_alb_target_group.tg-group.id}"]
    load_balancing_config {
      panic_threshold = 90
    }

    healthcheck {
      timeout             = "10s"
      interval            = "3s"
      healthy_threshold   = 10
      unhealthy_threshold = 15
      http_healthcheck {
        path = "/"
      }
    }
  }
}

#security groups
resource "yandex_vpc_security_group" "ssh-access" {
  name       = "ssh-access"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 22
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
  ingress {
    protocol          = "TCP"
    security_group_id = yandex_vpc_security_group.ssh-access-local.id
    port              = 22
  }
  egress {
    protocol          = "TCP"
    port              = 22
    security_group_id = yandex_vpc_security_group.ssh-access-local.id
  }
}

resource "yandex_vpc_security_group" "ssh-access-local" {
  name       = "ssh-access-local"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 22
  }
  egress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 22
  }
  egress {
    protocol       = "ANY"
    v4_cidr_blocks = ["0.0.0.0/0"]
    from_port      = 0
    to_port        = 65535
  }
}

resource "yandex_vpc_security_group" "nginx-sg" {
  name       = "nginx-sg"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "ANY"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    port           = 80
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

}

resource "yandex_vpc_security_group" "elasticsearch-sg" {
  name       = "elasticsearch-sg"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 9200
  }

  ingress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 9200
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
  }

  egress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

}


resource "yandex_vpc_security_group" "zabbix-sg" {
  name       = "zabbix-sg"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 8080
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 10050
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 10051
  }

  egress {
    protocol       = "TCP"
    port           = 8080
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    protocol       = "TCP"
    port           = 10050
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
  }

  egress {
    protocol       = "TCP"
    port           = 10051
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
  }
}


resource "yandex_vpc_security_group" "kibana-sg" {
  name       = "kibana-sg"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 5601
  }

  egress {
    protocol       = "ANY"
    port           = 10050
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    protocol       = "TCP"
    port           = 5601
    v4_cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "yandex_vpc_security_group" "filebeat-sg" {
  name       = "filebeat service"
  network_id = yandex_vpc_network.network-diplom.id

  ingress {
    protocol       = "TCP"
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
    port           = 5044
  }
  egress {
    protocol       = "TCP"
    port           = 5044
    v4_cidr_blocks = ["10.1.1.0/24", "10.2.1.0/24", "10.3.1.0/24", "10.4.1.0/24"]
  }
}

#sg-balancer

resource "yandex_vpc_security_group" "balancer-sg" {
  name       = "balancer-sg"
  network_id = yandex_vpc_network.network-diplom.id

  egress {
    protocol       = "ANY"
    description    = "any"
    v4_cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    protocol       = "TCP"
    description    = "ext-http"
    v4_cidr_blocks = ["0.0.0.0/0"]
    port           = 80
  }

  ingress {
    protocol          = "TCP"
    description       = "healthchecks"
    predefined_target = "loadbalancer_healthchecks"
    port              = 30080
  }
}