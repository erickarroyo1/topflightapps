module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13" # pinned on purpose: unpinned public modules are a supply-chain risk and break builds

  name = "vpc-${var.app}"
  cidr = "10.0.0.0/16"

  azs             = ["us-east-1a", "us-east-1b"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true # one NAT is fine for a demo; use one per AZ in production
  enable_dns_support   = true
  enable_dns_hostnames = true

  # VPC Flow Logs to CloudWatch: required evidence for SOC 2 / HIPAA network monitoring
  enable_flow_log                                 = true
  create_flow_log_cloudwatch_iam_role             = true
  create_flow_log_cloudwatch_log_group            = true
  flow_log_max_aggregation_interval               = 60
  flow_log_cloudwatch_log_group_retention_in_days = 90

  tags = local.common_tags
  providers = {
    aws = aws.landing-zone-account
  }
}
