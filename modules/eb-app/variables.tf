variable "description" {
  type        = string
  description = "Elastic Beanstalk application description"
  default     = ""
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

variable "environment_type" {
  type        = string
  description = "Environment type, e.g. 'LoadBalanced' or 'SingleInstance'.  If setting to 'SingleInstance', `rolling_update_type` must be set to 'Time', `updating_min_in_service` must be set to 0, and `loadbalancer_subnets` will be unused (it applies to the ELB, which does not exist in SingleInstance environments)"
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

variable "enable_spot_instances" {
  type        = bool
  default     = false
  description = "Enable Spot Instance requests for your environment"
}

variable "spot_fleet_on_demand_base" {
  type        = number
  default     = 0
  description = "The minimum number of On-Demand Instances that your Auto Scaling group provisions before considering Spot Instances as your environment scales up. This option is relevant only when enable_spot_instances is true."
}

variable "spot_fleet_on_demand_above_base_percentage" {
  type        = number
  default     = -1
  description = "The percentage of On-Demand Instances as part of additional capacity that your Auto Scaling group provisions beyond the SpotOnDemandBase instances. This option is relevant only when enable_spot_instances is true."
}

variable "spot_max_price" {
  type        = number
  default     = -1
  description = "The maximum price per unit hour, in US$, that you're willing to pay for a Spot Instance. This option is relevant only when enable_spot_instances is true. Valid values are between 0.001 and 20.0"
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

variable "tier" {
  type        = string
  description = "Elastic Beanstalk Environment tier, e.g. 'WebServer' or 'Worker'"
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

variable "healthcheck_url" {
  type        = string
  description = "Application Health Check URL. Elastic Beanstalk will call this URL to check the health of the application running on EC2 instances"
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

variable "allowed_inbound_security_groups" {
  type        = list(string)
  description = "Security groups allowed access to EB app"
  default     = []
}

# Options: https://docs.aws.amazon.com/elasticbeanstalk/latest/dg/command-options-specific.html
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
