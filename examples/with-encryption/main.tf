######################################################################
# EKS Cluster with Secrets Encryption and Custom Node Group
######################################################################
#
# Production-like configuration with KMS-encrypted Kubernetes secrets,
# larger node group, additional EBS CSI driver add-on, and all control
# plane log types enabled.
######################################################################

module "eks" {
  source = "../../"

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
