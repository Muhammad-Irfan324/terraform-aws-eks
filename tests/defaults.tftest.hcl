######################################################################
# Default Configuration
######################################################################
#
# Asserts that the default values for key settings are sensible and
# that the module produces the expected resource structure.
#
# Runs in plan mode against a mocked AWS provider: no credentials, no
# API calls, no infrastructure created, no cost.
######################################################################

mock_provider "aws" {
  mock_data "aws_partition" {
    defaults = {
      partition  = "aws"
      dns_suffix = "amazonaws.com"
    }
  }
}
mock_provider "tls" {}

variables {
  cluster_name = "test-cluster"
  vpc_id       = "vpc-0abc1234def56789a"
  subnet_ids   = ["subnet-0aaa1111", "subnet-0bbb2222"]
}

######################################################################
# Cluster Defaults
######################################################################

run "cluster_defaults" {
  command = plan

  assert {
    condition     = aws_eks_cluster.this.name == "test-cluster"
    error_message = "Cluster name must match the cluster_name variable."
  }

  assert {
    condition     = aws_eks_cluster.this.version == "1.35"
    error_message = "Default Kubernetes version must be 1.35."
  }
}

######################################################################
# Node Group Defaults
######################################################################

run "node_group_defaults" {
  command = plan

  assert {
    condition     = aws_eks_node_group.this["default"].node_group_name == "default"
    error_message = "Default node group name must be 'default'."
  }

  assert {
    condition     = aws_eks_node_group.this["default"].disk_size == 50
    error_message = "Default disk size must be 50 GB."
  }

  assert {
    condition     = aws_eks_node_group.this["default"].scaling_config[0].desired_size == 2
    error_message = "Default desired size must be 2."
  }

  assert {
    condition     = aws_eks_node_group.this["default"].scaling_config[0].min_size == 1
    error_message = "Default min size must be 1."
  }

  assert {
    condition     = aws_eks_node_group.this["default"].scaling_config[0].max_size == 4
    error_message = "Default max size must be 4."
  }
}

######################################################################
# Multiple Node Groups
######################################################################

run "multiple_node_groups" {
  command = plan

  variables {
    node_groups = {
      system   = { instance_types = ["t3.medium"], desired_size = 2 }
      workload = { instance_types = ["t3.large"], min_size = 2, max_size = 8 }
    }
  }

  assert {
    condition     = length(aws_eks_node_group.this) == 2
    error_message = "Two node groups must be created when two are defined."
  }
}

######################################################################
# Default Add-ons
######################################################################

run "default_addons_are_installed" {
  command = plan

  assert {
    condition     = length(aws_eks_addon.this) == 4
    error_message = "Four default add-ons (vpc-cni, coredns, kube-proxy, aws-ebs-csi-driver) must be created."
  }
}

######################################################################
# OIDC Provider for IRSA
######################################################################

run "oidc_provider_created" {
  command = plan

  assert {
    condition     = length(aws_iam_openid_connect_provider.cluster.client_id_list) == 1
    error_message = "OIDC provider must have exactly one client ID."
  }
}

######################################################################
# No Encryption When Key Not Provided
######################################################################

run "no_encryption_without_key" {
  command = plan

  assert {
    condition     = length(aws_eks_cluster.this.encryption_config) == 0
    error_message = "Secrets encryption must not be enabled when cluster_encryption_key_arn is null."
  }
}

######################################################################
# Encryption Enabled When Key Provided
######################################################################

run "encryption_with_key" {
  command = plan

  variables {
    cluster_encryption_key_arn = "arn:aws:kms:eu-west-1:111122223333:key/00000000-0000-0000-0000-000000000000"
  }

  assert {
    condition     = length(aws_eks_cluster.this.encryption_config) == 1
    error_message = "Secrets encryption must be enabled when cluster_encryption_key_arn is set."
  }
}
