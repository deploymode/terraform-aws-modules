variable "aws_account_id" {
  type = string
}

variable "aws_region" {
  type = string
}

// Networking
variable "vpc_id" {
  type        = string
  description = "VPC ID"
}

variable "vpc_cidr" {
  type        = string
  description = "VPC CIDR block"
}

variable "public_subnet_ids" {
  type        = list(string)
  description = "List of public subnet IDs"
}

variable "private_subnet_ids" {
  type        = list(string)
  description = "List of private subnet IDs"
}

variable "ecs_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to allow into ECS Service"
  default     = []
}

variable "peered_vpc_id" {
  type        = string
  description = "VPC ID for a VPC with which to set up peering"
  default     = ""
}

// ALB

variable "use_alb_security_group" {
  type        = bool
  description = "A flag to enable/disable adding the ingress rule to the ALB security group"
  default     = false
}

# variable "alb_target_group_arn" {
#   type        = string
#   description = "ARN of load balancer target group"
#   default     = null
# }

# variable "alb_security_group_id" {
#   type        = string
#   description = "Security group of the ALB"
# }

variable "alb_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to allow access to ALB"
  default     = []
}

# variable "alb_dns_name" {
#   type        = string
#   description = "HTTP endpoint for ALB"
# }

# variable "alb_zone_id" {
#   type        = string
#   description = "Route 53 zone ID for ALB"
# }

variable "alb_healthcheck_path" {
  type        = string
  description = "Health check path used by the ALB"
  default     = "/"
}

variable "alb_healthcheck_timeout" {
  type        = number
  description = "The amount of time to wait in seconds before failing a health check request"
  default     = 10
}

variable "alb_healthcheck_interval" {
  type        = number
  description = "The duration in seconds in between health checks"
  default     = 15
}

variable "target_group_port" {
  type        = number
  default     = 80
  description = "The port for target group traffic"
}

variable "http_port" {
  type        = number
  default     = 80
  description = "The port for the HTTP listener"
}

variable "http_enabled" {
  type        = bool
  default     = true
  description = "A boolean flag to enable/disable HTTP listener"
}

variable "certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the default SSL certificate for ALB HTTPS listener"
}

variable "cdn_certificate_arn" {
  type        = string
  default     = ""
  description = "The ARN of the SSL certificate for CloudFront - must be in us-east-2"
}

variable "https_port" {
  type        = number
  default     = 443
  description = "The port for the HTTPS listener"
}

variable "https_enabled" {
  type        = bool
  default     = false
  description = "A boolean flag to enable/disable HTTPS listener"
}

variable "http_to_https_redirect" {
  type        = bool
  default     = false
  description = "Whether to redirect HTTP to HTTPS"
}

variable "create_alb_dns_record" {
  type        = bool
  default     = false
  description = "Whether to create an alias to the ALB endpoint or not"
}

variable "domain_name" {
  type        = string
  description = "Main Route 53 hosted zone name"
  default     = ""
}

variable "hosted_zone_id" {
  type        = string
  description = "Main Route 53 hosted zone ID."
  default     = ""
}

variable "app_dns_name" {
  type        = string
  description = "Subdomain prepended to `domain_name`. Typically \"app\"."
  default     = "app"
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  type        = bool
  default     = true
  description = "A boolean that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
}

// ECR

variable "ecr_max_image_count" {
  type        = number
  description = "Maximum number of images to store before ECR lifecycle rules delete oldest"
  default     = 500
}

// ECS

variable "ecs_cluster_arn" {
  type        = string
  description = "ECS cluster ARN"
}

variable "ecs_cluster_name" {
  type        = string
  description = "ECS cluster name"
}

// ECS Service Variables

variable "ecs_deployment_controller_type" {
  type        = string
  default     = "ECS"
  description = "Deployment controller type"
}

variable "ecs_launch_type" {
  type        = string
  default     = "FARGATE"
  description = "ECS Cluster type"
}

variable "ecs_platform_version" {
  type        = string
  default     = "LATEST"
  description = "Fargate version"
}

variable "service_force_new_deployment" {
  type        = bool
  description = "Enable to force a new task deployment of the service."
  default     = false
}

variable "ecs_capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "The capacity provider strategies to use for the service. See `capacity_provider_strategy` configuration block: https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy"
  default     = []
}

variable "ecs_ignore_changes_task_definition" {
  type        = bool
  description = "Whether to ignore changes in container definition and task definition in the ECS service"
  default     = true
}





// ECS Task Variables

# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task-networking.html
# https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#network_mode
variable "ecs_network_mode" {
  type        = string
  default     = "awsvpc" # REQUIRED for Fargate
  description = "ECS Network Mode"
}

variable "ecs_task_cpu" {
  type    = number
  default = 512
}

variable "ecs_task_memory" {
  type    = number
  default = 1024
}

variable "ecs_task_desired_count" {
  type        = number
  description = "The number of instances of the task definition to run when creating the service"
  default     = 0
}

variable "assign_public_ip" {
  type        = bool
  description = "Should containers have public IPs assigned? Setting this to true avoids needing a NAT gateway."
  default     = true
}

variable "security_group_ids" {
  type        = list(any)
  description = "Additional security groups that should have access to the ECS service"
  default     = []
}

variable "ecs_enable_exec" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service. Creates required IAM policies."
  default     = false
}

variable "ecs_task_policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the ECS task role"
  default     = []
}

variable "allow_email_sending" {
  type        = bool
  description = "If true, adds IAM policy to ECS task role to allow sending email with SES"
  default     = false
}

// Container variables

variable "log_driver" {
  type        = string
  description = "Docker log driver"
  default     = "awslogs"
}

variable "container_start_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before giving up on resolving dependencies for a container"
  default     = 30
}

variable "container_stop_timeout" {
  type        = number
  description = "Time duration (in seconds) to wait before the container is forcefully killed if it doesn't exit normally on its own"
  default     = 30
}

variable "container_cpu_nginx" {
  type        = number
  description = "CPU limit for nginx container"
  default     = 512
}
variable "container_memory_nginx" {
  type        = number
  description = "Hard memory limit"
  default     = 256
}
variable "container_memory_reservation_nginx" {
  type        = number
  description = "Soft memory limit"
  default     = 128
}


// Container settings - PHP
variable "container_cpu_php" {
  type        = number
  description = "CPU limit for php container"
  default     = 512
}
variable "container_memory_php" {
  type        = number
  description = "Hard memory limit"
  default     = 256
}
variable "container_memory_reservation_php" {
  type        = number
  description = "Soft memory limit"
  default     = 128
}

variable "container_environment_nginx" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Container environment variables for nginx containers"
  default     = []
}

variable "container_environment_php" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Container environment variables for php-fpm containers"
  default     = []
}

variable "container_ssm_secrets_nginx" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Container secret variables stored in SSM parameter store for nginx containers"
  default     = []
}

variable "container_ssm_secrets_php" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "Container secret variables stored in SSM parameter store for php-fpm containers"
  default     = []
}

// CodePipeline

variable "codepipeline_enabled" {
  type        = bool
  description = "Enable CodePipeline project"
  default     = true
}

variable "codestar_provider_type" {
  type        = string
  description = "Specified provider type if you wish the module to create a Codestar connection. Valid values: Bitbucket, GitHub or GitHubEnterpriseServer. Note the connection is created in a PENDING state and must be manually authorised. Ignored if `codestar_connection_arn` provided."
}

variable "codestar_output_artifact_format" {
  type        = string
  description = "Output artifact type for Source stage in pipeline. Valid values are \"CODE_ZIP\" (default) and \"CODEBUILD_CLONE_REF\". See https://docs.aws.amazon.com/codepipeline/latest/userguide/action-reference-CodestarConnectionSource.html"
  default     = "CODE_ZIP"
}

variable "codestar_connection_arn" {
  type        = string
  description = "OAuth2 Codestar connection ARN"
  default     = null
}

variable "codepipeline_repo_owner" {
  type        = string
  description = "GitHub/Bitbucket Organization or Username"
  default     = ""
}

variable "codepipeline_repo_name" {
  type        = string
  description = "GitHub/Bitbucket repository name of the application to be built and deployed to ECS"
  default     = ""
}

variable "codepipeline_branch" {
  type        = string
  description = "Branch of the git repository, e.g. `master`"
  default     = ""
}

variable "codepipeline_build_image" {
  type        = string
  default     = "aws/codebuild/docker:17.09.0"
  description = "Docker image for build environment, _e.g._ `aws/codebuild/docker:docker:17.09.0`"
}

variable "codepipeline_build_timeout" {
  type        = number
  default     = 60
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
}

variable "codepipeline_environment_variables" {
  type = list(object(
    {
      name  = string
      value = string
      type  = string
  }))
  description = "A list of maps, that contain the keys 'name', 'value', and 'type' to be used as additional environment variables for the build. Valid types are 'PLAINTEXT', 'PARAMETER_STORE', or 'SECRETS_MANAGER'"
  default     = []
}

// CodePipeline notifications

variable "codepipeline_slack_notification_webhook_url" {
  type        = string
  description = "Slack webhook URL for receiving CodePipeline notifications"
  default     = ""
}

variable "codepipeline_slack_notification_channel" {
  type        = string
  description = "Slack channel for receiving CodePipeline notifications"
  default     = ""
}

variable "codepipeline_slack_notification_event_ids" {
  type        = list(any)
  description = "The list of event type to trigger a notification on"
  default = [
    "codepipeline-pipeline-pipeline-execution-failed",
    "codepipeline-pipeline-pipeline-execution-canceled",
    "codepipeline-pipeline-pipeline-execution-started",
    "codepipeline-pipeline-pipeline-execution-resumed",
    "codepipeline-pipeline-pipeline-execution-succeeded",
    "codepipeline-pipeline-pipeline-execution-superseded"
  ]
}

variable "test_report_names" {
  type        = map(any)
  description = "CodeBuild test report names"
  default = {
    "UnitTestReports" = "build/logs"
    "IntTestReports"  = "int_tests/reports"
  }
}

variable "codebuild_cache_type" {
  type        = string
  default     = "S3"
  description = "The type of storage that will be used for the AWS CodeBuild project cache. Valid values: NO_CACHE, LOCAL, and S3.  Defaults to S3.  If cache_type is S3, it will create an S3 bucket for storing codebuild cache inside"
}

variable "codebuild_local_cache_modes" {
  type        = list(string)
  default     = []
  description = "Specifies settings that AWS CodeBuild uses to store and reuse build dependencies. Valid values: LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, and LOCAL_CUSTOM_CACHE"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#vpc_config
variable "codebuild_vpc_config" {
  type        = any
  default     = {}
  description = "Configuration for the builds to run inside a VPC."
}

// Redis

variable "provision_redis_cache" {
  type        = bool
  description = "Provision an Elasticache Redis instance"
  default     = false
}

variable "redis_availability_zones" {
  type        = list(string)
  description = "Availability zone IDs"
  default     = []
}

variable "redis_allowed_security_groups" {
  type        = list(string)
  default     = []
  description = "List of Security Group IDs that are allowed ingress to the cluster's Security Group created in the module"
}

variable "redis_cluster_mode_enabled" {
  type        = bool
  description = "Flag to enable/disable creation of a native redis cluster. `automatic_failover_enabled` must be set to `true`. Only 1 `cluster_mode` block is allowed"
  default     = false
}

variable "redis_cluster_size" {
  type        = number
  default     = 1
  description = "Number of nodes in cluster. *Ignored when `cluster_mode_enabled` == `true`*"
}

# https://docs.aws.amazon.com/AmazonElastiCache/latest/red-ug/CacheNodes.SupportedTypes.html
variable "redis_instance_type" {
  type        = string
  default     = "cache.t4g.micro"
  description = "Elastic cache instance type"
}

variable "redis_family" {
  type        = string
  default     = "redis6.x"
  description = "Redis family"
}

variable "redis_engine_version" {
  type        = string
  default     = "6.2"
  description = "Redis engine version"
}

variable "redis_password" {
  type        = string
  description = "Auth token for password protecting redis, `transit_encryption_enabled` must be set to `true`. Password must be longer than 16 chars"
  default     = null

}

// Redis

variable "provision_dynamodb_cache" {
  type        = bool
  description = "Provision a DynamoDB table for app cache"
  default     = false
}

variable "dynamodb_cache_ttl_attribute" {
  type        = string
  default     = "expires_at"
  description = "DynamoDB table TTL attribute"
}

// Queue

variable "queue_name" {
  type        = string
  description = "Name of SQS queue used by application (if any)"
  default     = ""
}

// Buckets

variable "external_app_buckets" {
  type        = list(string)
  description = "Existing S3 buckets used by the application. Used to allow application roles to access buckets."
  default     = []
}

// CDN / CloudFront

variable "use_cdn" {
  type        = bool
  default     = false
  description = "Whether to create a CloudFront distro in front of the ALB endpoint or not"
}

variable "cdn_viewer_min_protocol_version" {
  type        = string
  description = "Minimum TLS standard for clients"
  default     = "TLSv1.2_2019"
}

variable "cdn_default_ttl" {
  type        = number
  description = "Default TTL for CloudFront"
  default     = 3600
}

variable "cdn_min_ttl" {
  type        = number
  description = "Min TTL for CloudFront"
  default     = 0
}

variable "cdn_max_ttl" {
  type        = number
  description = "Max TTL for CloudFront"
  default     = 86400
}

variable "cdn_logging_enabled" {
  type        = bool
  default     = false
  description = "When true, access logs will be sent to a newly created s3 bucket"
}

variable "create_frontend_website" {
  type        = bool
  default     = false
  description = "Provision a CDN in front of an S3 bucket. Bucket provide in `external_app_buckets` with key 'public'."
}

variable "frontend_dns_name" {
  type        = string
  default     = "www"
  description = "Used if `create_frontend_website` is true. DNS name used for frontend CDN."
}

// ECS Deployment

variable "ecs_circuit_breaker_deployment_enabled" {
  type        = bool
  description = "If `true`, enable the deployment circuit breaker logic for the service"
  default     = true
}

variable "ecs_circuit_breaker_rollback_enabled" {
  type        = bool
  description = "If `true`, Amazon ECS will roll back the service if a service deployment fails"
  default     = true
}

# Monitoring container (optional)
variable "monitoring_image_name" {
  type        = string
  default     = null
  description = "Docker Hub image name"
}

variable "monitoring_container_memory" {
  type        = number
  default     = 128
  description = "Memory hard-limit for monitoring container"
}

variable "monitoring_container_memory_reservation" {
  type        = number
  default     = 64
  description = "Memory soft-limit for monitoring container"
}

variable "monitoring_container_cpu" {
  type        = number
  default     = 256
  description = "Memory soft-limit for monitoring container"
}

variable "monitoring_container_port" {
  type        = number
  default     = 8080
  description = "Container port to expose for monoitoring container"
}

variable "monitoring_container_dependency" {
  type        = bool
  default     = false
  description = "If true, the php container will depend on the monitoring container. This is necessary in some cases where the monitoring daemon must be up before the agent in the app container tries to connect."
}
