# VMware Cloud Foundation (VCF) Lab Automation

PowerCLI automation for applying a vCenter inventory tag to every virtual machine visible to the configured vCenter account.

## Terraform for the vSphere lab

A starter Terraform configuration is available under [terraform/environments/lab](terraform/environments/lab). It uses the VMware vSphere provider to perform a read-only lookup of the configured vCenter datacenter. It does not create or modify VMs, networks, datastores, clusters, or other vSphere objects.

See [Terraform README](terraform/README.md) for the folder layout, local-state policy, credential setup, and validation steps.

**Safety:** Terraform state remains local and is excluded from Git. Real `.tfvars` files and credentials are excluded from Git. Only the example variables file is committed. Do not run `terraform apply` until a future change has been reviewed.

## Test the vCenter connection

The `.github/workflows/test-vcenter-connection.yml` workflow is a manual, read-only connectivity check. It connects to vCenter, reads product/version/build details and counts VMs visible to the account, then disconnects. It does not create, update, or delete vCenter objects.

The workflow uses a **self-hosted GitHub Actions runner** because a private homelab vCenter is normally not reachable from GitHub-hosted runners. Install PowerShell 7 on the runner and register it with this repository. The runner must be on a trusted network that can resolve and reach the vCenter FQDN.

Configure the existing `vcenter-lab` GitHub Actions environment:

| Name | Type | Value |
|---|---|---|
| `VCENTER_SERVER` | Variable | `vc01.skillservices.com.au` |
| `VCENTER_USERNAME` | Secret | Your vCenter account |
| `VCENTER_PASSWORD` | Secret | Your vCenter password |

Do not place passwords in workflow files, scripts, or commits. Use a dedicated least-privilege account where possible.

When vCenter is powered on and the runner is online, open **Actions → Test vCenter Connection → Run workflow**. The workflow is manual only and will not run until you start it. The script uses a session-only PowerCLI certificate warning setting for a self-signed lab certificate; use a trusted certificate with strict validation for production.

For local testing, install VMware PowerCLI and set the three environment variables above, then run:

```powershell
./scripts/Test-VCenterConnection.ps1
```

## GitHub Actions: tag all VMs

The `.github/workflows/tag-vms.yml` workflow is manual only. It has no push or schedule trigger.

Defaults:
- Category: `Automation` (Multiple cardinality, VirtualMachine entity type)
- Tag: `ManagedBy-GitHubActions`
- `apply=false`: dry run; no vCenter changes
- `apply=true`: create the category/tag if needed and tag VMs not already tagged

### Configure GitHub

Create a GitHub Actions environment named `vcenter-lab` under **Settings → Environments**. Configure required reviewers there if you want an approval gate.

Add these environment variables/secrets:

| Name | Type | Value |
|---|---|---|
| `VCENTER_SERVER` | Variable | vCenter FQDN |
| `VCENTER_USERNAME` | Secret | Dedicated least-privilege vCenter account |
| `VCENTER_PASSWORD` | Secret | Account password |

Never store credentials in source code. Grant the account only the inventory-read and tag-management permissions needed.

### Run it

1. Open **Actions → Apply vCenter VM Tags → Run workflow**.
2. Leave `apply` set to `false` and inspect the log.
3. Confirm the correct VMs and planned changes.
4. Run again with `apply=true` only when ready; approve the `vcenter-lab` environment if reviewers are configured.

### Local use

Install VMware PowerCLI and set `VCENTER_SERVER`, `VCENTER_USERNAME`, and `VCENTER_PASSWORD` as environment variables, then:

```powershell
# Preview only
./scripts/Set-VCenterVmTags.ps1

# Apply after reviewing the preview
./scripts/Set-VCenterVmTags.ps1 -Apply
```

### Scope and safety

- The script tags all VMs returned by `Get-VM` for the connected vCenter. It does not filter by cluster, folder, or datacenter.
- It does not remove existing tags or change VM power, names, placement, or guest OS.
- This is vCenter inventory tagging, not guest OS tagging.
- GitHub-hosted runners usually cannot reach a private homelab vCenter. Use a secured self-hosted runner on a trusted network with vCenter connectivity if required.
- Lab certificates are configured with PowerCLI's warning mode. For production, use a trusted vCenter certificate and strict validation.
