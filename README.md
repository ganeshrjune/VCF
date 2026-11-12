# VMware Cloud Foundation (VCF) Lab Automation

PowerCLI automation for applying a vCenter inventory tag to every virtual machine visible to the configured vCenter account.

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
