variable "description" {
  type        = string
  description = "Elastic Beanstalk application description"
  default     = ""
}

# More info: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/iam-servicerole.html
variable "appversion_lifecycle_service_role_arn" {
  type        = string
  description = "The service role ARN to use for application version cleanup. If left empty, the `appversion_lifecycle` block will not be created. \"arn:aws:iam::$${account_id}:role/aws-elasticbeanstalk-service-role\" can be used if you don't wish to create a custom role."
  default     = ""
}

variable "appversion_lifecycle_max_count" {
  type        = number
  default     = 1000
  description = "The max number of application versions to keep"
}

variable "appversion_lifecycle_delete_source_from_s3" {
  type        = bool
  default     = false
  description = "Whether to delete application versions from S3 source"
}

variable "environment_name" {
  type        = string
  description = "Name of EB environment"
  default     = null
}

variable "region" {
  type        = string
  description = "AWS region"
}

variable "vpc_id" {
  type        = string
  description = "AWS VPC ID"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "Public subnet IDs (typically ALB subnets)"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "Private subnet IDs"
}

variable "availability_zones" {
  type        = list(string)
  description = "List of availability zones"
}

variable "set_dns_env_vars" {
  type        = bool
  description = "If true, will add env vars containing EB DNS Zone ID and EB web endpoint"
  default     = false
}

variable "environment_settings" {
  // @todo: use optional() when it's no longer experimental
  type = map(object({
    tier                                       = string
    environment_type                           = string
    enable_spot_instances                      = bool
    spot_fleet_on_demand_base                  = number
    spot_fleet_on_demand_above_base_percentage = number
    spot_max_price                             = number
    env_vars                                   = map(string)
  }))
  description = <<EOT
  A map of environment name to a settings object:

  - tier: "WebServer" or "Worker" (https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-properties-beanstalk-environment-tier.html)
  - environment_type: "Environment type, e.g. 'LoadBalanced' or 'SingleInstance'.  If setting to 'SingleInstance', `rolling_update_type` must be set to 'Time', `updating_min_in_service` must be set to 0, and `loadbalancer_subnets` will be unused (it applies to the ELB, which does not exist in SingleInstance environments)"
  - enable_spot_instances: Allow use of spot instances
  - spot_fleet_on_demand_base: Used by auto-scaling - number of on-demand EC2 instances to maintain
  - spot_fleet_on_demand_above_base_percentage: Used by auto-scaling - basically an on-demand buffer above base to maintain before using spot instances
  
  e.g.
  {
    "web" = {
      tier = "WebServer"
      environment_type = "LoadBalanced"
      enable_spot_instances = false
      spot_fleet_on_demand_base                  = 0
      spot_fleet_on_demand_above_base_percentage = -1
      spot_max_price                             = -1
      env_vars = {
        SPECIFIC_WEB_VAR = "example"
      }
    }
    "worker" = {
      tier = "Worker"
      environment_type = "LoadBalanced"
      enable_spot_instances = true
      spot_fleet_on_demand_base                  = 1
      spot_fleet_on_demand_above_base_percentage = 70
      spot_max_price                             = -1
      env_vars = {}
    }
  }
EOT
}

variable "loadbalancer_type" {
  type        = string
  description = "Load Balancer type, e.g. 'application' or 'classic'"
}

variable "dns_zone_id" {
  type        = string
  description = "Route53 parent zone ID. The module will create sub-domain DNS record in the parent zone for the EB environment"
}

variable "dns_subdomain" {
  type        = string
  description = "The subdomain to create on Route53 for the EB environment. For the subdomain to be created, the `dns_zone_id` variable must be set as well"
  default     = ""
}

variable "availability_zone_selector" {
  type        = string
  description = "Availability Zone selector"
}

variable "instance_type" {
  type        = string
  description = "Instances type"
}

variable "create_key_pair" {
  type        = bool
  description = "Create EC2 keypair and ssh keys locally"
  default     = false
}

variable "ssh_key_path" {
  type        = string
  default     = "~/.ssh"
  description = "Path for SSH key storage"
}

variable "autoscale_min" {
  type        = number
  description = "Minumum instances to launch"
}

variable "autoscale_max" {
  type        = number
  description = "Maximum instances to launch"
}

variable "solution_stack_name" {
  type        = string
  description = "Elastic Beanstalk stack, e.g. Docker, Go, Node, Java, IIS. For more info, see https://docs.aws.amazon.com/elasticbeanstalk/latest/platforms/platforms-supported.html"
}

variable "wait_for_ready_timeout" {
  type        = string
  description = "The maximum duration to wait for the Elastic Beanstalk Environment to be in a ready state before timing out"
}

variable "version_label" {
  type        = string
  description = "Elastic Beanstalk Application version to deploy"
}

variable "force_destroy" {
  type        = bool
  description = "Force destroy the S3 bucket for load balancer logs"
}

variable "rolling_update_enabled" {
  type        = bool
  description = "Whether to enable rolling update"
}

variable "rolling_update_type" {
  type        = string
  description = "`Health` or `Immutable`. Set it to `Immutable` to apply the configuration change to a fresh group of instances"
}

variable "updating_min_in_service" {
  type        = number
  description = "Minimum number of instances in service during update"
}

variable "updating_max_batch" {
  type        = number
  description = "Maximum number of instances to update at once"
}

variable "deployment_ignore_health_check" {
  type        = bool
  default     = false
  description = "Do not cancel a deployment due to failed health checks. Useful to set to `true` when first stabilising app config."
}

variable "deployment_timeout" {
  type        = number
  default     = 600
  description = "Number of seconds to wait for an instance to complete executing commands"
}

variable "healthcheck_url" {
  type        = string
  description = "Application Health Check URL. Elastic Beanstalk will call this URL to check the health of the application running on EC2 instances"
}

variable "monitoring_ignore_app_4xx" {
  type        = bool
  description = "Ignore HTTP 4xx errors in EB monitoring"
  default     = false
}

variable "enable_stream_logs" {
  type        = bool
  default     = false
  description = "Whether to create groups in CloudWatch Logs for proxy and deployment logs, and stream logs from each instance in your environment"
}

variable "application_port" {
  type        = number
  description = "Port application is listening on"
}

variable "root_volume_size" {
  type        = number
  description = "The size of the EBS root volume"
}

variable "root_volume_type" {
  type        = string
  description = "The type of the EBS root volume"
}

variable "autoscale_measure_name" {
  type        = string
  description = "Metric used for your Auto Scaling trigger"
}

variable "autoscale_statistic" {
  type        = string
  description = "Statistic the trigger should use, such as Average"
}

variable "autoscale_unit" {
  type        = string
  description = "Unit for the trigger measurement, such as Bytes"
}

variable "autoscale_lower_bound" {
  type        = number
  description = "Minimum level of autoscale metric to remove an instance"
}

variable "autoscale_lower_increment" {
  type        = number
  description = "How many Amazon EC2 instances to remove when performing a scaling activity."
}

variable "autoscale_upper_bound" {
  type        = number
  description = "Maximum level of autoscale metric to add an instance"
}

variable "autoscale_upper_increment" {
  type        = number
  description = "How many Amazon EC2 instances to add when performing a scaling activity"
}

variable "associated_security_group_ids" {
  type        = list(string)
  default     = []
  description = <<-EOT
    A list of IDs of Security Groups to associate the created resource with, in addition to the created security group.
    These security groups will not be modified and, if `create_security_group` is `false`, must have rules providing the desired access.
    EOT
}

variable "elb_scheme" {
  type        = string
  description = "Specify `internal` if you want to create an internal load balancer in your Amazon VPC so that your Elastic Beanstalk application cannot be accessed from outside your Amazon VPC"
  default     = "public"
}

variable "loadbalancer_certificate_arn" {
  type        = string
  default     = ""
  description = "Load Balancer SSL certificate ARN. The certificate must be present in AWS Certificate Manager"
}

variable "loadbalancer_ssl_policy" {
  type        = string
  default     = "ELBSecurityPolicy-2016-08"
  description = "Specify a security policy to apply to the listener. This option is only applicable to environments with an application load balancer, and is required if `loadbalancer_certificate_arn` is set."
}

variable "redirect_http_to_https" {
  type        = bool
  default     = false
  description = "Add a listener rule to the load balancer config to redirect HTTP requests to HTTPS"

}

variable "allowed_inbound_security_groups" {
  type        = list(string)
  description = "Security groups allowed access to EB app"
  default     = []
}

# Options:
#   - https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-specific.html
#   - https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html
variable "additional_settings" {
  type = list(object({
    namespace = string
    name      = string
    value     = string
  }))

  description = "Additional Elastic Beanstalk setttings. For full list of options, see https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-general.html"
  default     = []
}

variable "env_vars" {
  type        = map(string)
  default     = {}
  description = "Map of custom ENV variables to be provided to the application running on Elastic Beanstalk, e.g. env_vars = { DB_USER = 'admin' DB_PASS = 'xxxxxx' }"
}

variable "secrets_file" {
  type        = string
  default     = null
  description = "Path to JSON file containing a list of maps. The keys of these values will be added as EB env vars. It is assumed the values are already in SSM Param Store."
}

variable "scheduled_actions" {
  type = list(object({
    name            = string
    minsize         = string
    maxsize         = string
    desiredcapacity = string
    starttime       = string
    endtime         = string
    recurrence      = string
    suspend         = bool
  }))
  default     = []
  description = "Define a list of scheduled actions"
}

# IAM

variable "ec2_policy_documents" {
  type        = map(any)
  default     = {}
  description = "Additional policy document JSON for the EC2 instances within the EB App"
}

# SQS

variable "queue_name" {
  type        = string
  description = "SQS queue name for app"
  default     = ""
}

variable "queue_http_url" {
  type        = string
  description = "SQS queue name for app"
  default     = "/"
}
