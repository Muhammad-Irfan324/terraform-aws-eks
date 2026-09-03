######################################################################
# Basic EKS Cluster
######################################################################
#
# Minimal configuration — creates an EKS cluster with a managed node
# group using all defaults. Only the cluster name, VPC, and subnets
# are required.
######################################################################

module "eks" {
  source = "../../"

  cluster_name = "my-cluster"
  vpc_id       = "vpc-0abc1234def56789a"
  subnet_ids   = ["subnet-0aaa1111", "subnet-0bbb2222", "subnet-0ccc3333"]
}
