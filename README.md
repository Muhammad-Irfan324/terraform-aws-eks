# terraform-aws-eks

Terraform module for creating an AWS EKS cluster with a managed node group, OIDC provider for IRSA, configurable add-ons, and optional secrets encryption.

The module creates the cluster IAM role, node group IAM role, security group, OIDC provider, and default add-ons (vpc-cni, coredns, kube-proxy) out of the box. Everything is configurable through variables.

```hcl
module "eks" {
  source = "github.com/Muhammad-Irfan324/terraform-aws-eks?ref=v1.0.0"

  cluster_name = "my-cluster"
  vpc_id       = "vpc-0abc1234def56789a"
  subnet_ids   = ["subnet-0aaa1111", "subnet-0bbb2222", "subnet-0ccc3333"]
}
```

Pin `ref` to a released tag. Releases are cut automatically from `main` by semantic-release, so commit messages drive the version number.

### Production configuration with encryption

```hcl
module "eks" {
  source = "github.com/Muhammad-Irfan324/terraform-aws-eks?ref=v1.0.0"

  cluster_name       = "prod-cluster"
  vpc_id             = "vpc-0abc1234def56789a"
  subnet_ids         = ["subnet-0aaa1111", "subnet-0bbb2222", "subnet-0ccc3333"]
  kubernetes_version = "1.35"

  cluster_encryption_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/00000000-0000-0000-0000-000000000000"

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  node_groups = {
    system = {
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 2
      max_size       = 3
    }
    workload = {
      instance_types = ["t3.large"]
      desired_size   = 3
      min_size       = 2
      max_size       = 10
      disk_size      = 100
    }
  }

  cluster_addons = {
    vpc-cni            = {}
    coredns            = {}
    kube-proxy         = {}
    aws-ebs-csi-driver = {}
  }

  tags = {
    Environment = "production"
    Team        = "platform"
  }
}
```

## What the module creates

| Resource | Purpose |
|----------|---------|
| EKS cluster | Managed Kubernetes control plane |
| Cluster IAM role | Lets the EKS service manage AWS resources |
| Cluster security group | Controls traffic to and from the control plane |
| OIDC provider | Enables IRSA (IAM Roles for Service Accounts) |
| Managed node groups | Worker nodes that run your pods (supports multiple groups via `node_groups` map) |
| Node group IAM role | Lets worker nodes pull images and join the cluster (shared across all groups) |
| EKS add-ons | vpc-cni, coredns, kube-proxy by default (configurable) |

## IRSA (IAM Roles for Service Accounts)

The module creates an OIDC provider automatically, so you can bind IAM roles to Kubernetes service accounts without sharing node-level credentials. Use the `oidc_provider_arn` and `oidc_provider_url` outputs in your IAM role trust policies.

## Add-ons

Four add-ons are installed by default: `vpc-cni`, `coredns`, `kube-proxy`, and `aws-ebs-csi-driver`. Override the `cluster_addons` variable to add more or to pin a specific version.

Set `cluster_addons = {}` to skip all add-ons.

## Secrets encryption

Pass `cluster_encryption_key_arn` to encrypt Kubernetes secrets at rest with a customer-managed KMS key. When null (the default), secrets encryption is not enabled.

## Examples

- [Basic](examples/basic) — minimal usage with defaults
- [With Encryption](examples/with-encryption) — KMS encryption, custom node group, EBS CSI driver

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | >= 4.0 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.62.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.4.0 |

## Modules

No modules.

## Resources

| Name | Type |
| ---- | ---- |
| [aws_eks_addon.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.node_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_vpc_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_ecr](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_worker](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster_egress](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the EKS cluster and node groups (at least 2 in different AZs) | `list(string)` | n/a | yes |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | ID of the VPC where the EKS cluster will be deployed | `string` | n/a | yes |
| <a name="input_cluster_addons"></a> [cluster\_addons](#input\_cluster\_addons) | Map of EKS add-ons to install. Keys are add-on names, values are<br/>objects with an optional version override. When version is null the<br/>latest compatible version is installed automatically.<br/><br/>Common add-ons: vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver. | <pre>map(object({<br/>    version = optional(string, null)<br/>  }))</pre> | <pre>{<br/>  "aws-ebs-csi-driver": {},<br/>  "coredns": {},<br/>  "kube-proxy": {},<br/>  "vpc-cni": {}<br/>}</pre> | no |
| <a name="input_cluster_encryption_key_arn"></a> [cluster\_encryption\_key\_arn](#input\_cluster\_encryption\_key\_arn) | ARN of the KMS key to encrypt Kubernetes secrets at rest. When null, secrets encryption is disabled. | `string` | `null` | no |
| <a name="input_cluster_endpoint_private_access"></a> [cluster\_endpoint\_private\_access](#input\_cluster\_endpoint\_private\_access) | Whether the Kubernetes API server endpoint is accessible from within the VPC | `bool` | `true` | no |
| <a name="input_cluster_endpoint_public_access"></a> [cluster\_endpoint\_public\_access](#input\_cluster\_endpoint\_public\_access) | Whether the Kubernetes API server endpoint is publicly accessible | `bool` | `true` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of EKS control plane log types to enable (api, audit, authenticator, controllerManager, scheduler) | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator"<br/>]</pre> | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the EKS cluster | `string` | `"1.35"` | no |
| <a name="input_node_groups"></a> [node\_groups](#input\_node\_groups) | Map of managed node groups to create. Each key becomes the node group<br/>name. All fields are optional and fall back to sensible defaults.<br/><br/>Example:<br/>  node\_groups = {<br/>    system   = { instance\_types = ["t3.medium"], desired\_size = 2 }<br/>    workload = { instance\_types = ["t3.large"],  min\_size = 2, max\_size = 10 }<br/>  } | <pre>map(object({<br/>    instance_types = optional(list(string), ["t3.medium"])<br/>    ami_type       = optional(string, "AL2023_x86_64_STANDARD")<br/>    disk_size      = optional(number, 50)<br/>    desired_size   = optional(number, 2)<br/>    min_size       = optional(number, 1)<br/>    max_size       = optional(number, 4)<br/>  }))</pre> | <pre>{<br/>  "default": {}<br/>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags applied to all resources created by this module | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | ARN of the EKS cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64-encoded certificate data for the cluster CA |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint URL for the Kubernetes API server |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Name of the EKS cluster |
| <a name="output_cluster_role_arn"></a> [cluster\_role\_arn](#output\_cluster\_role\_arn) | ARN of the IAM role used by the EKS cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | ID of the security group attached to the EKS cluster control plane |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | Kubernetes version running on the cluster |
| <a name="output_node_group_names"></a> [node\_group\_names](#output\_node\_group\_names) | Names of all managed node groups created by this module |
| <a name="output_node_group_role_arn"></a> [node\_group\_role\_arn](#output\_node\_group\_role\_arn) | ARN of the IAM role shared by all managed node groups |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC provider for IRSA (IAM Roles for Service Accounts) |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | URL of the OIDC provider (without https:// prefix) |
<!-- END_TF_DOCS -->

## License

Apache 2.0 Licensed. See [LICENSE](LICENSE).
