locals {
  database_username = var.database_user == null ? module.db_username_label.id : var.database_user
  database_password = var.database_password == "" ? join("", random_password.password.*.result) : var.database_password
}

module "db_username_label" {
  source          = "cloudposse/label/null"
  version         = "0.25.0"
  attributes      = ["admin"]
  delimiter       = ""
  id_length_limit = "16"
  enabled         = module.this.enabled && var.database_user == null
  context         = module.this.context
}

# taint this resource to create a new password
resource "random_password" "password" {
  count            = var.database_password == "" ? 1 : 0
  keepers          = var.database_password_settings.keepers
  length           = var.database_password_settings.length
  numeric          = var.database_password_settings.numeric
  min_numeric      = var.database_password_settings.min_numeric
  upper            = var.database_password_settings.upper
  min_upper        = var.database_password_settings.min_upper
  lower            = var.database_password_settings.lower
  min_lower        = var.database_password_settings.min_lower
  special          = var.database_password_settings.special
  override_special = var.database_password_settings.override_special
}


module "sg_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["db", "allowed"]
  enabled    = module.this.enabled && var.provision_security_group
  context    = module.this.context
}

resource "aws_security_group" "allowed" {
  count = module.this.enabled && var.provision_security_group ? 1 : 0

  name        = module.sg_label.id
  description = "Services which need DB access can be assigned this security group"
  vpc_id      = var.vpc_id
  tags        = module.this.tags
}

resource "aws_security_group_rule" "egress" {
  count             = module.this.enabled && var.provision_security_group ? 1 : 0
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.allowed.*.id)
}

module "rds_cluster" {
  source  = "cloudposse/rds-cluster/aws"
  version = "2.1.0"

  engine         = var.engine
  engine_version = var.engine_version
  engine_mode    = var.engine_mode
  cluster_size   = var.cluster_size
  cluster_family = var.cluster_family

  vpc_id                     = var.vpc_id
  security_groups            = concat(var.allowed_security_group_ids, aws_security_group.allowed[*].id)
  subnets                    = var.subnet_ids
  instance_availability_zone = var.instance_availability_zone
  subnet_group_name          = var.subnet_group_name
  zone_id                    = var.dns_zone_id
  publicly_accessible        = var.publicly_accessible
  ca_cert_identifier         = var.ca_cert_identifier

  admin_user     = local.database_username
  admin_password = local.database_password
  db_name        = var.database_name
  db_port        = var.database_port

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage
  storage_encrypted = var.storage_encrypted
  iops              = var.iops

  instance_type = var.instance_class

  deletion_protection         = var.deletion_protection
  auto_minor_version_upgrade  = var.auto_minor_version_upgrade
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately
  maintenance_window          = var.maintenance_window

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports
  rds_monitoring_interval         = var.monitoring_interval
  rds_monitoring_role_arn         = var.monitoring_role_arn

  # Backups
  skip_final_snapshot      = var.skip_final_snapshot
  copy_tags_to_snapshot    = var.copy_tags_to_snapshot
  retention_period         = var.backup_retention_period
  backup_window            = var.backup_window
  restore_to_point_in_time = var.restore_to_point_in_time
  snapshot_identifier      = var.snapshot_identifier

  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_kms_key_id       = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null

  serverlessv2_scaling_configuration = var.serverlessv2_scaling_configuration

  cluster_parameters               = var.cluster_parameters
  rds_cluster_parameter_group_name = var.rds_cluster_parameter_group_name
  instance_parameters              = var.instance_parameters
  db_parameter_group_name          = var.db_parameter_group_name

  kms_key_arn = var.kms_key_arn

  context = module.this.context
}

module "store_write" {
  source  = "cloudposse/ssm-parameter-store/aws"
  version = "0.10.0"

  enabled = module.this.enabled && var.db_username_ssm_param_path != ""

  parameter_write_defaults = {
    overwrite       = "true"
    data_type       = "text"
    type            = "SecureString"
    allowed_pattern = null
    tier            = "Standard"
  }

  parameter_write = [
    {
      name        = var.db_username_ssm_param_path
      value       = local.database_username
      description = "${module.this.stage} database master user"
    },
    {
      name        = var.db_password_ssm_param_path
      value       = local.database_password
      description = "${module.this.stage} database master user password"
    }
  ]

  context = module.this.context
}
