# Read-only inventory lookup. This data source does not create or modify vSphere objects.
data "vsphere_datacenter" "lab" {
  name = var.datacenter_name
}
