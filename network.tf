resource "yandex_vpc_network" "VPC" {
  name = "VPC"
}

resource "yandex_vpc_subnet" "subnet-public" {
  name           = "public"
  zone           = var.default_zone
  network_id     = yandex_vpc_network.VPC.id
  v4_cidr_blocks = ["192.168.10.0/24"]
}