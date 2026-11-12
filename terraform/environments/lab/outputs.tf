output "datacenter_name" {
  description = "Name of the vCenter datacenter found by the read-only lookup."
  value       = data.vsphere_datacenter.lab.name
}

output "datacenter_id" {
  description = "Managed object ID of the vCenter datacenter."
  value       = data.vsphere_datacenter.lab.id
}
