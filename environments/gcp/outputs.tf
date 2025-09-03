

output "gcp_vpc_self_link" {
  value = module.vpc.gcp_vpc_self_link
}

output "gcp_private_subnet_cidrs" {
  value = module.vpc.gcp_private_subnet_cidrs
}

output "gcp_public_subnet_cidrs" {
  value = module.vpc.gcp_public_subnet_cidrs
}

