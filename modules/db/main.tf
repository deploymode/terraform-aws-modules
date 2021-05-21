resource "random_password" "password" {
  count            = var.database_password == "" ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

module "sg_label" {
  source     = "cloudposse/label/null"
  version    = "0.24.1"
  attributes = ["db", "allowed"]
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
  count             = module.this.enabled ? 1 : 0
  description       = "Allow all egress traffic"
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = join("", aws_security_group.allowed.*.id)
}

module "rds_instance" {
  source = "git::https://github.com/joe-niland/terraform-aws-rds.git?ref=avoid-sec-group-count-issue"
  # source      = "cloudposse/rds/aws"
  # version     = "0.35.1"
  dns_zone_id = var.dns_zone_id
  host_name   = var.host_name
  security_group_ids = compact(
    concat(
      aws_security_group.allowed.*.id,
      var.allowed_security_group_ids
  ))
  ca_cert_identifier = "rds-ca-2019"
  # allowed_cidr_blocks         = ["XXX.XXX.XXX.XXX/32"]
  database_name      = var.database_name
  database_user      = var.database_user
  database_password  = var.database_password == "" ? random_password.password[0].result : var.database_password
  database_port      = var.database_port
  multi_az           = false
  storage_type       = var.storage_type
  allocated_storage  = var.allocated_storage
  storage_encrypted  = true
  engine             = var.engine
  engine_version     = var.engine_version
  instance_class     = var.instance_class
  db_parameter_group = var.db_parameter_group
  # option_group_name           = "mysql-options"
  publicly_accessible = false
  subnet_ids          = var.subnet_ids
  vpc_id              = var.vpc_id
  # snapshot_identifier         = "rds:production-2015-06-26-06-05"
  deletion_protection         = var.deletion_protection
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  maintenance_window          = var.maintenance_window
  skip_final_snapshot         = var.skip_final_snapshot
  copy_tags_to_snapshot       = true
  backup_retention_period     = var.backup_retention_period
  backup_window               = var.backup_window

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
