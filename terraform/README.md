# Terraform AWS infrastructure

## Remote state setup

Run the separate, dispatch-only `Bootstrap Terraform State` workflow to create or reconcile the state bucket. It uses `terraform/bootstrap`, enables versioning, encryption and public-access blocking, and stores the bootstrap state at `bootstrap/terraform.tfstate`.

After the bucket has been created, migrate the existing application state from a trusted local checkout that has the state file. The deployment runner cannot access ignored local state files. Check that `terraform/terraform.tfstate.backup` contains the existing resources before using it; if the active `terraform/terraform.tfstate` is empty and the backup is the valid state, preserve both files and restore the backup as the active local state:

```bash
cp terraform/terraform.tfstate terraform/terraform.tfstate.empty-backup
cp terraform/terraform.tfstate.backup terraform/terraform.tfstate
```

Then migrate the state from the repository root. Replace the bucket name and region with the values configured in GitHub:

```bash
terraform -chdir=terraform init -migrate-state -force-copy \
  -backend-config='bucket=your-globally-unique-state-bucket' \
  -backend-config='key=development/terraform.tfstate' \
  -backend-config='region=us-east-1' \
  -backend-config='encrypt=true' \
  -backend-config='use_lockfile=true'
```

Confirm the migration by running `terraform -chdir=terraform state list` and checking that it includes `aws_instance.server`. Then review `terraform -chdir=terraform plan` before running the deployment workflow. Do not commit either state file; state can contain sensitive data.

The bucket's bootstrap configuration has a `prevent_destroy` lifecycle rule to help protect it from accidental deletion. The AWS role used by the bootstrap workflow needs permission to check the bucket and create/configure it when absent.

The dispatch-only `Deploy Development` workflow checks for the application state object at `development/terraform.tfstate` before initializing Terraform. If state exists, the workflow verifies it tracks `aws_instance.server` before applying. If state is missing, the workflow stops by default. For a genuinely new environment with no existing infrastructure, dispatch it again with **`create_infrastructure` checked**; Terraform will plan and create the resources, then write the initial state to S3 during apply. Do not select this option for existing infrastructure with missing state—migrate its state first to avoid recreating resources.

Both workflows read repository-level variables and secrets from **Settings → Secrets and variables → Actions**:

- Variables: `AWS_ROLE_ARN`, `AWS_REGION`, `TF_STATE_BUCKET`, `ANSIBLE_USER` (optional; defaults to `ubuntu`), `DUCKDNS_DOMAIN`, and `LETSENCRYPT_EMAIL`.
- Secrets: `ADMIN_SSH_IP` (your public IPv4 address, with or without `/32`), `EC2_SSH_PRIVATE_KEY` (the EC2 key pair's private key), and `DUCKDNS_TOKEN`.

Configure the AWS role to trust GitHub Actions through OIDC and grant only the needed infrastructure permissions plus access to this bucket and both state objects' `.tflock` lock files. Since these jobs do not use a GitHub Environment, scope the OIDC trust policy to the repository and permitted branch/ref, rather than an `environment:development` subject. The deployment workflow temporarily adds the runner's public IPv4 as a separate SSH rule, then runs Ansible from the GitHub runner over SSH. The inventory uses `StrictHostKeyChecking=accept-new` so OpenSSH automatically records the EC2 host fingerprint on first connection rather than requiring a manual SSH connection beforehand. The playbook issues the certificate after starting the application, and the workflow removes the runner rule even if deployment fails.

Migrate the existing application state before dispatching deployment to avoid attempting to recreate existing infrastructure.

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.71.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eip.server_eip](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip) | resource |
| [aws_eip_association.server_ip_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eip_association) | resource |
| [aws_instance.server](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_internet_gateway.main_gateway](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/internet_gateway) | resource |
| [aws_route_table.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table) | resource |
| [aws_route_table_association.public_subnet1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route_table_association) | resource |
| [aws_security_group.allow_tls_ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_subnet.subnet1](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/subnet) | resource |
| [aws_vpc.main](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc) | resource |
| [aws_vpc_security_group_egress_rule.allow_all_traffic](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_egress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_vpc_security_group_ingress_rule.ssh_runner](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/vpc_security_group_ingress_rule) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_owner"></a> [ami\_owner](#input\_ami\_owner) | The owner ID for the Ubuntu AMI | `string` | `"099720109477"` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The instance type for the EC2 instance | `string` | `"t3.micro"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | The name of the key pair to use for the EC2 instance | `string` | `"tut ec2"` | no |
| <a name="input_region"></a> [region](#input\_region) | The AWS region to create resources in | `string` | `"us-east-1"` | no |
| <a name="input_security_group_cidr_egress"></a> [security\_group\_cidr\_egress](#input\_security\_group\_cidr\_egress) | The CIDR block for the security group egress rule | `string` | `"0.0.0.0/0"` | no |
| <a name="input_security_group_cidr_ingress_ssh"></a> [security\_group\_cidr\_ingress\_ssh](#input\_security\_group\_cidr\_ingress\_ssh) | The CIDR block for the security group SSH rule | `string` | n/a | yes |
| <a name="input_security_group_cidr_ingress_ssh_runner"></a> [security\_group\_cidr\_ingress\_ssh\_runner](#input\_security\_group\_cidr\_ingress\_ssh\_runner) | Temporary GitHub Actions runner CIDR for SSH access | `string` | `null` | no |
| <a name="input_security_group_cidr_ingress_web"></a> [security\_group\_cidr\_ingress\_web](#input\_security\_group\_cidr\_ingress\_web) | The CIDR block for the security group | `string` | `"0.0.0.0/0"` | no |
| <a name="input_subnet_cidr"></a> [subnet\_cidr](#input\_subnet\_cidr) | The CIDR block for the subnet | `string` | `"10.0.1.0/24"` | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR block for the VPC | `string` | `"10.0.0.0/16"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_server_public_ip"></a> [server\_public\_ip](#output\_server\_public\_ip) | public ip of EC2 |
<!-- END_TF_DOCS -->
