# vSphere lab connection check

This environment performs a read-only lookup of one vCenter datacenter. It does not create, update, or delete infrastructure.

## 1. Prerequisites

- Terraform CLI 1.5 or later.
- Network and DNS connectivity from this machine to `vc01.skillservices.com.au`.
- A vCenter account with permission to view the target datacenter.
- The exact datacenter inventory name from vCenter.

## 2. Configure variables (PowerShell)

From this directory:

```powershell
Copy-Item terraform.tfvars.example terraform.tfvars
notepad terraform.tfvars
```

Replace `REPLACE_WITH_VCENTER_DATACENTER_NAME` with the exact inventory name.

Set credentials in the current PowerShell session. Do not paste them into a file or commit them:

```powershell
$env:TF_VAR_vsphere_user = Read-Host "vCenter username"
$securePassword = Read-Host "vCenter password" -AsSecureString
$env:TF_VAR_vsphere_password = [System.Net.NetworkCredential]::new("", $securePassword).Password
```

The password is held in the process environment for this terminal session. Close the terminal when finished.

## 3. Initialize and validate

```powershell
terraform init
terraform fmt -check -recursive
terraform validate
```

## 4. Run the read-only plan

```powershell
terraform plan
```

Expected result: Terraform reads the datacenter and reports no managed resource changes. A data source lookup may fail if the datacenter name, credentials, DNS, network path, or certificate trust is incorrect.

## Certificate handling

Certificate validation is enabled by default. For a self-signed certificate in this isolated lab only, you can temporarily set:

```powershell
$env:TF_VAR_allow_unverified_ssl = "true"
```

Prefer installing/trusting the correct vCenter certificate and leaving this setting false. Do not use unverified TLS in production.

## State and cleanup

The default backend is local. Terraform creates a local `terraform.tfstate` after a successful plan that reads data sources. It is ignored by Git and must not be committed or shared. No remote backend is configured.

Do not run `terraform apply` for this starter configuration. No vSphere resources are defined.
