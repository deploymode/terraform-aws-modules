resource "random_password" "password" {
  count            = var.database_password == "" ? 1 : 0
  length           = 16
  special          = true
  override_special = "_%@"
}

module "rds_instance" {
  source             = "cloudposse/rds/aws"
  version            = "0.35.1"
  dns_zone_id        = var.dns_zone_id
  host_name          = var.host_name
  security_group_ids = var.allowed_security_group_ids
  ca_cert_identifier = "rds-ca-2019"
  # allowed_cidr_blocks         = ["XXX.XXX.XXX.XXX/32"]
  database_name     = module.this.name
  database_user     = var.database_user
  database_password = var.database_password == "" ? random_password.password[0].result : var.database_password
  database_port     = var.database_port
  multi_az          = false
  storage_type      = var.storage_type
  allocated_storage = var.allocated_storage
  storage_encrypted = true
  engine            = var.engine
  engine_version    = var.engine_version
  instance_class    = var.instance_class
  # db_parameter_group          = "mysql5.7"
  # option_group_name           = "mysql-options"
  publicly_accessible = false
  subnet_ids          = var.subnet_ids
  vpc_id              = var.vpc_id
  # snapshot_identifier         = "rds:production-2015-06-26-06-05"
  deletion_protection         = var.deletion_protection
  auto_minor_version_upgrade  = true
  allow_major_version_upgrade = false
  apply_immediately           = true
  maintenance_window          = "Sun:03:00-Mon:04:00"
  skip_final_snapshot         = false
  copy_tags_to_snapshot       = true
  backup_retention_period     = 14
  backup_window               = "13:00-18:00"

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
