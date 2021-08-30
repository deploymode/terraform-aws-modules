module "aws_key_pair" {
  source              = "cloudposse/key-pair/aws"
  version             = "0.18.0"
  attributes          = ["ssh", "key"]
  ssh_public_key_path = var.ssh_key_path
  generate_ssh_key    = var.generate_ssh_key

  context = module.this.context
}

module "ec2_bastion" {
  source  = "cloudposse/ec2-bastion-server/aws"
  version = "0.28.3"

  enabled = module.this.enabled

  instance_type               = var.instance_type
  security_groups             = var.security_groups
  subnets                     = var.public_subnet_ids
  key_name                    = module.aws_key_pair.key_name
  user_data                   = var.user_data
  user_data_template          = var.user_data_template
  vpc_id                      = var.vpc_id
  associate_public_ip_address = var.associate_public_ip_address

  context = module.this.context
}
