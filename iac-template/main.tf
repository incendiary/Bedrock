provider "aws" {
  region = var.region

  default_tags {
    tags = local.common_tags
  }
}

locals {
  # Every resource inherits these tags via the provider default_tags block.
  common_tags = {
    project = var.project
    owner   = var.owner
    ttl     = var.ttl
  }
}

# Add resources and modules below. Keep every range private: private subnets,
# SSM Session Manager access only, default-deny security groups, and
# least-privilege egress. Do not add public ingress.
