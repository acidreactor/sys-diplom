#основная сеть
resource "yandex_vpc_network" "network-diplom" {
  name        = "network-diplom"
  description = "diplom"
}

#подсеть для веб серивиса 1
resource "yandex_vpc_subnet" "private-1" {
  name           = "private-1"
  description    = "subnet-1"
  v4_cidr_blocks = ["10.1.1.0/24"]
  zone           = "ru-central1-a"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

#подсеть для веб серивиса 2
resource "yandex_vpc_subnet" "private-2" {
  name           = "private-2"
  description    = "subnet-2"
  v4_cidr_blocks = ["10.2.1.0/24"]
  zone           = "ru-central1-b"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

#подсеть для остальных сервисов
resource "yandex_vpc_subnet" "private-3" {
  name           = "private-3"
  description    = "subnet services"
  v4_cidr_blocks = ["10.3.1.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-diplom.id
  route_table_id = yandex_vpc_route_table.route_table.id
}

#публичная подсеть для бастиона, кибаны
resource "yandex_vpc_subnet" "public-subnet" {
  name           = "public-subnet"
  description    = "subnet bastion"
  v4_cidr_blocks = ["10.4.1.0/24"]
  zone           = "ru-central1-c"
  network_id     = yandex_vpc_network.network-diplom.id
}

#настройка nat и статический маршрут через бастион для внутренней сети
resource "yandex_vpc_gateway" "nat_gateway" {
  name = "gateway"
  shared_egress_gateway {}
}

resource "yandex_vpc_route_table" "route_table" {
  network_id = yandex_vpc_network.network-diplom.id

  static_route {
    destination_prefix = "0.0.0.0/0"
    gateway_id         = yandex_vpc_gateway.nat_gateway.id
  }
}