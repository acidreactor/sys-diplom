variable "yc_token" {
  type        = string
  description = "Your Yandex.Cloud token"
}
variable "yc_cloud_id" {
  type        = string
  description = "Your Yandex.Cloud cloud_id"
}
variable "yc_folder_id" {
  type        = string
  description = "Your Yandex.Cloud folder_id"
}

variable "image_id" {
  default = "fd8vljd295nqdaoogf3g"
}


locals {
  web-servers = {
    "web-vm-1" = { zone = "ru-central1-a", subnet_id = yandex_vpc_subnet.private-1.id, ip_address = "10.1.1.10" },
    "web-vm-2" = { zone = "ru-central1-b", subnet_id = yandex_vpc_subnet.private-2.id, ip_address = "10.2.1.20" }
  }
}