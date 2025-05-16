variable "dns_zone_id" {
  type        = string
  default     = ""
  description = "The ID of the DNS Zone in Route53 where a new DNS record will be created for the DB host name"
}

variable "provision_security_group" {
  type        = bool
  default     = false
  description = "If true, create security group which can be assigned to resources needing DB access"
}

variable "allowed_security_group_ids" {
  type        = list(string)
  default     = []
  description = "The IDs of the security groups from which to allow `ingress` traffic to the DB instance"
}

variable "database_name" {
  type        = string
  description = "The name of the database to create when the DB instance is created"
  default     = null
}

# https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/USER_CreateDBInstance.html
variable "database_user" {
  type        = string
  default     = null
  description = "(Required unless a `snapshot_identifier` or `replicate_source_db` is provided) Username for the master DB user"
}

variable "db_username_ssm_param_path" {
  type        = string
  default     = ""
  description = "SSM param store path for db username"
}

variable "database_password" {
  type        = string
  default     = ""
  description = "(Required unless a snapshot_identifier or replicate_source_db is provided) Password for the master DB user"
}

variable "db_password_ssm_param_path" {
  type        = string
  default     = ""
  description = "SSM param store path for db user password"
}

variable "database_password_settings" {
  type = object({
    length           = optional(number, 16)
    numeric          = optional(bool, true)
    min_numeric      = optional(number, 0)
    upper            = optional(bool, true)
    min_upper        = optional(number, 0)
    lower            = optional(bool, true)
    min_lower        = optional(number, 0)
    special          = optional(bool, false)
    override_special = optional(string, "_-<>;()&#!^")
    keepers          = optional(map(string), null)
  })
  description = "Database password characteristics"
  default = {
    length = 16
  }
}

variable "database_port" {
  type        = number
  description = "Database port (_e.g._ `3306` for `MySQL`). Used in the DB Security Group to allow access to the DB instance from the provided `security_group_ids`"
}

variable "deletion_protection" {
  type        = bool
  description = "Set to true to enable deletion protection on the RDS instance"
  default     = false
}

variable "storage_type" {
  type        = string
  description = "One of 'standard' (magnetic), 'gp2' (general purpose SSD), 'gp3' (general purpose SSD), or 'io1' (provisioned IOPS SSD)"
  default     = null
}

variable "storage_encrypted" {
  type        = bool
  description = "(Optional) Specifies whether the DB instance is encrypted. The default is true if not specified"
  default     = true
}

variable "iops" {
  type        = number
  description = "The amount of provisioned IOPS. Setting this implies a storage_type of 'io1'. Default is null if rds storage type is not 'io1'"
  default     = null
}

variable "allocated_storage" {
  type        = number
  description = "The allocated storage in GBs"
  default     = null
}

variable "engine" {
  type        = string
  description = "Database engine type"
  # http://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
  # - mysql
  # - postgres
  # - oracle-*
  # - sqlserver-*
}

variable "engine_version" {
  type        = string
  description = "Database engine version, depends on engine type"
  # http://docs.aws.amazon.com/cli/latest/reference/rds/create-db-instance.html
}

variable "engine_mode" {
  type        = string
  description = "Database engine mode, depends on engine type. Valid values: parallelquery, provisioned, serverless, global"
  default     = ""
}

variable "instance_class" {
  type        = string
  description = "Class of RDS instance"
  # https://docs.aws.amazon.com/AmazonRDS/latest/UserGuide/Concepts.DBInstanceClass.html
}

variable "publicly_accessible" {
  type        = bool
  description = "Determines if database can be publicly available (NOT recommended)"
  default     = false
}

variable "subnet_ids" {
  description = "List of subnet IDs for the DB. DB instance will be created in the VPC associated with the DB subnet group provisioned using the subnet IDs. Specify one of `subnet_ids`, `db_subnet_group_name` or `availability_zone`"
  type        = list(string)
  default     = []
}

variable "instance_availability_zone" {
  type        = string
  default     = null
  description = "The AZ for the RDS instance. Specify one of `subnet_ids`, `db_subnet_group_name` or `availability_zone`. If `availability_zone` is provided, the instance will be placed into the default VPC or EC2 Classic"
}

variable "subnet_group_name" {
  type        = string
  default     = null
  description = "Name of DB subnet group. DB instance will be created in the VPC associated with the DB subnet group. Specify one of `subnet_ids`, `db_subnet_group_name` or `availability_zone`"
}

variable "vpc_id" {
  type        = string
  description = "VPC ID the DB instance will be created in"
}

variable "auto_minor_version_upgrade" {
  type        = bool
  description = "Allow automated minor version upgrade (e.g. from Postgres 9.5.3 to Postgres 9.5.4)"
  default     = true
}

variable "allow_major_version_upgrade" {
  type        = bool
  description = "Allow major version upgrade"
  default     = false
}

variable "apply_immediately" {
  type        = bool
  description = "Specifies whether any database modifications are applied immediately, or during the next maintenance window"
  default     = true
}

variable "maintenance_window" {
  type        = string
  description = "The window to perform maintenance in. Syntax: 'ddd:hh24:mi-ddd:hh24:mi' UTC "
  default     = "Mon:03:00-Mon:04:00"
}

variable "skip_final_snapshot" {
  type        = bool
  description = "If true (default), no snapshot will be made before deleting DB"
  default     = true
}

variable "copy_tags_to_snapshot" {
  type        = bool
  description = "Copy tags from DB to a snapshot"
  default     = true
}

variable "backup_retention_period" {
  type        = number
  description = "Backup retention period in days. Must be > 0 to enable backups"
  default     = 0
}

variable "backup_window" {
  type        = string
  description = "When AWS can perform DB snapshots, can't overlap with maintenance window"
  default     = "22:00-03:00"
}

variable "cluster_parameters" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
  description = "List of DB cluster parameters to apply"
}

variable "instance_parameters" {
  type = list(object({
    apply_method = string
    name         = string
    value        = string
  }))
  default     = []
  description = "List of DB instance parameters to apply"
}

variable "rds_cluster_parameter_group_name" {
  type        = string
  default     = ""
  description = <<-EOT
    The name to give to the created `aws_rds_cluster_parameter_group` resource.
    If omitted, the module will generate a name.
    EOT
}

variable "db_parameter_group_name" {
  type        = string
  default     = ""
  description = <<-EOT
    The name to give to the created `aws_db_parameter_group` resource.
    If omitted, the module will generate a name.
    EOT
}

variable "snapshot_identifier" {
  type        = string
  description = "Snapshot identifier e.g: `rds:project-prod-2023-06-26-06-05` or `manual-backup-2023-11-16`. If specified, the module creates the instance from this snapshot."
  default     = null
}

variable "kms_key_arn" {
  type        = string
  description = "The ARN of the existing KMS key to encrypt storage"
  default     = ""
}

variable "performance_insights_enabled" {
  type        = bool
  default     = false
  description = <<EOT
  Specifies whether Performance Insights are enabled.
  Not supported for micro and small instances, and some others.
EOT
}

variable "performance_insights_kms_key_id" {
  type        = string
  default     = null
  description = "The ARN for the KMS key to encrypt Performance Insights data. Once KMS key is set, it can never be changed."
}

variable "performance_insights_retention_period" {
  type        = number
  default     = 7
  description = "The amount of time in days to retain Performance Insights data. Either 7 (7 days) or 731 (2 years)."
}

variable "enabled_cloudwatch_logs_exports" {
  type        = list(string)
  default     = []
  description = "List of log types to enable for exporting to CloudWatch logs. If omitted, no logs will be exported. Valid values (depending on engine): alert, audit, error, general, listener, slowquery, trace, postgresql (PostgreSQL), upgrade (PostgreSQL)."
}

variable "ca_cert_identifier" {
  type        = string
  description = "The identifier of the CA certificate for the DB instance"
  default     = "rds-ca-rsa4096-g1"
}

variable "monitoring_interval" {
  type        = number
  description = "The interval, in seconds, between points when Enhanced Monitoring metrics are collected for the DB instance. To disable collecting Enhanced Monitoring metrics, specify 0. Valid Values are 0, 1, 5, 10, 15, 30, 60."
  default     = 0
}

variable "monitoring_role_arn" {
  type        = string
  description = "The ARN for the IAM role that permits RDS to send enhanced monitoring metrics to CloudWatch Logs"
  default     = null
}

variable "iam_database_authentication_enabled" {
  type        = bool
  description = "Specifies whether or mappings of AWS Identity and Access Management (IAM) accounts to database accounts is enabled"
  default     = false
}

variable "restore_to_point_in_time" {
  type = list(object({
    source_cluster_identifier  = string
    restore_type               = optional(string, "copy-on-write")
    use_latest_restorable_time = optional(bool, true)
    restore_to_time            = optional(string, null)
  }))
  default     = []
  description = <<-EOT
    List of point-in-time recovery options. Valid parameters are:

    `source_cluster_identifier`
      Identifier of the source database cluster from which to restore.
    `restore_type`:
      Type of restore to be performed. Valid options are "full-copy" and "copy-on-write".
    `use_latest_restorable_time`:
      Set to true to restore the database cluster to the latest restorable backup time. Conflicts with `restore_to_time`.
    `restore_to_time`:
      Date and time in UTC format to restore the database cluster to. Conflicts with `use_latest_restorable_time`.
EOT
}

# Cluster Settings

variable "cluster_size" {
  type        = number
  default     = 2
  description = "Number of DB instances to create in the cluster"
}


variable "serverlessv2_scaling_configuration" {
  type = object({
    min_capacity = number
    max_capacity = number
    # upstream module doesn't support this yet - default is 300s
    # seconds_until_auto_pause = number
  })
  default     = null
  description = "serverlessv2 scaling properties"
}

variable "cluster_family" {
  type        = string
  default     = "aurora-postgresql17"
  description = "The family of the DB cluster parameter group"
}
