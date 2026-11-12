variable "vsphere_server" {
  description = "vCenter Server FQDN or IP address."
  type        = string
  default     = "vc01.skillservices.com.au"
}

variable "vsphere_user" {
  description = "vCenter service account or lab account. Supply using TF_VAR_vsphere_user."
  type        = string
  sensitive   = true
}

variable "vsphere_password" {
  description = "vCenter password. Supply using TF_VAR_vsphere_password."
  type        = string
  sensitive   = true
}

variable "datacenter_name" {
  description = "Exact inventory name of the vCenter datacenter to look up."
  type        = string
}

variable "allow_unverified_ssl" {
  description = "Allow an untrusted/self-signed vCenter certificate. Lab use only."
  type        = bool
  default     = false
}
