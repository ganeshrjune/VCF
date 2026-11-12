# Terraform lab

This repository keeps Terraform separate from the existing PowerCLI scripts and GitHub Actions workflows.

## Layout

```text
terraform/
├── environments/
│   └── lab/                 # Root module for the home lab
│       ├── versions.tf
│       ├── providers.tf
│       ├── variables.tf
│       ├── main.tf
│       ├── outputs.tf
│       ├── terraform.tfvars.example
│       └── README.md
└── modules/
    └── vm/                  # Reserved for a reviewed VM module
        └── README.md
```

## Current scope

The lab root module only authenticates to vCenter and reads the configured datacenter inventory object. It is deliberately read-only: no Terraform-managed vSphere resources have been defined yet.

## State and secrets

- The backend is local. No remote backend, cloud storage account, or paid service is configured.
- Local state and Terraform working files are ignored by Git.
- Real `.tfvars` files are ignored; commit only `terraform.tfvars.example`.
- Credentials are supplied through `TF_VAR_vsphere_user` and `TF_VAR_vsphere_password` environment variables, not source files.
- State files can contain sensitive infrastructure information. Keep local state on a trusted machine and do not upload it to GitHub.

## Next step

Follow [the lab instructions](environments/lab/README.md), run `terraform init`, `terraform fmt -check`, `terraform validate`, and then `terraform plan`. Review the plan before considering any future resource creation. Do not run `terraform apply` as part of this initial setup.
