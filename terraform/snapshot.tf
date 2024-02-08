#снимки дисков
resource "yandex_compute_snapshot_schedule" "snapshots" {
  name = "snapshots"

  schedule_policy {
    expression = "0 15 ? * *"
  }

  retention_period = "168h"

  snapshot_count = 7

  snapshot_spec {
    description = "daily-snapshot"
  }

  disk_ids = [
    "${yandex_compute_instance.bastion-vm.boot_disk.0.disk_id}",
    "${yandex_compute_instance.web-vm-1.boot_disk.0.disk_id}",
    "${yandex_compute_instance.web-vm-2.boot_disk.0.disk_id}",
    "${yandex_compute_instance.zabbix-vm.boot_disk.0.disk_id}",
    "${yandex_compute_instance.elasticsearch-vm.boot_disk.0.disk_id}",
  "${yandex_compute_instance.kibana-vm.boot_disk.0.disk_id}", ]
}
