# DNS Primary

## Alternative

If you don't require DNSSEC, I recommend using the `cloudposse/components/aws//modules/dns-primary` module instead.

### Terragrunt replacement example

```hcl
terraform {
  source = "tfr://registry.terraform.io/cloudposse/components/aws//modules/dns-primary?version=1.521.0"
}

# Include all settings from the root terragrunt.hcl file
include {
  path = find_in_parent_folders()
}

# These are the variables we have to pass in to use the module specified in the terragrunt configuration above
inputs = {
  domain_names = [
    "acme.com",
  ]
}
```

### Terraform replacement example

```hcl
module "dns_primary" {
  source = "cloudposse/components/aws//modules/dns-primary"
  version = "1.521.0"

  domain_names = [
    "acme.com"
  ]
}
```
