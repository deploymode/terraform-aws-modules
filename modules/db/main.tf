locals {
  database_username = var.database_user == null ? module.db_username_label.id : var.database_user
  database_password = var.database_password == "" ? join("", random_password.password.*.result) : var.database_password
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

module "db_username_label" {
  source          = "cloudposse/label/null"
  version         = "0.25.0"
  attributes      = ["admin"]
  delimiter       = ""
  id_length_limit = "16"
  enabled         = module.this.enabled && var.database_user == null
  context         = module.this.context
}

module "rds_instance" {
  # source = "git::https://github.com/joe-niland/terraform-aws-rds.git?ref=feat/restore-to-point-in-time"
  source  = "cloudposse/rds/aws"
  version = "1.1.2"

  publicly_accessible = false
  availability_zone   = var.availability_zone
  multi_az            = false
  subnet_ids          = var.subnet_ids
  vpc_id              = var.vpc_id
  security_group_ids  = aws_security_group.allowed.*.id
  # allowed_cidr_blocks         = ["XXX.XXX.XXX.XXX/32"]
  ca_cert_identifier = var.ca_cert_identifier

  dns_zone_id = var.dns_zone_id
  host_name   = var.host_name

  engine         = var.engine
  engine_version = var.engine_version
  

  database_name     = var.database_name
  database_user     = local.database_username
  database_password = local.database_password
  database_port     = var.database_port

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted = var.storage_encrypted

  instance_class    = var.instance_class

  snapshot_identifier = var.snapshot_identifier
  deletion_protection = var.deletion_protection

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = true
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = true
  backup_retention_period     = var.backup_retention_period
  backup_window               = var.backup_window

  db_parameter_group   = var.db_parameter_group
  parameter_group_name = var.parameter_group_name
  option_group_name    = var.option_group_name

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  restore_to_point_in_time = var.restore_to_point_in_time

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

  db_parameter = var.db_parameter
  db_options = var.db_options
  
  # db_parameter = [
  #   { name  = "myisam_sort_buffer_size"   value = "1048576" },
  #   { name  = "sort_buffer_size"          value = "2097152" }
  # ]

  # db_options = [
  #   { option_name = "MARIADB_AUDIT_PLUGIN"
  #       option_settings = [
  #         { name = "SERVER_AUDIT_EVENTS"           value = "CONNECT" },
  #         { name = "SERVER_AUDIT_FILE_ROTATIONS"   value = "37" }
  #       ]
  #   }
  # ]

  context = module.this.context
}

module "rds_replica" {
  source  = "cloudposse/rds/aws"
  version = "1.1.2"

  attributes = ["replica"]

  enabled = module.this.enabled && var.create_replica

  replicate_source_db = !var.promote_replica ? module.rds_instance.instance_id : null

  # subnet_ids          = var.subnet_ids
  availability_zone = var.availability_zone_replica
  vpc_id              = var.vpc_id
  security_group_ids  = aws_security_group.allowed.*.id
  associate_security_group_ids = [module.rds_instance.security_group_id]
  ca_cert_identifier = var.ca_cert_identifier

  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  dns_zone_id = var.dns_zone_id
  host_name   = var.replica_host_name

  database_port     = var.database_port

  storage_type      = var.storage_type
  max_allocated_storage = var.max_allocated_storage
  storage_encrypted = var.storage_encrypted

  instance_class    = var.instance_class

  engine = var.engine
  engine_version = var.engine_version

  deletion_protection = var.deletion_protection

  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = true
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = true
  backup_retention_period     = var.backup_retention_period
  backup_window               = var.backup_window

  db_parameter_group   = var.db_parameter_group
  parameter_group_name = var.parameter_group_name
  option_group_name    = var.option_group_name

  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  restore_to_point_in_time = var.restore_to_point_in_time

  performance_insights_enabled = var.performance_insights_enabled
  performance_insights_kms_key_id = var.performance_insights_kms_key_id
  performance_insights_retention_period = var.performance_insights_retention_period

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
