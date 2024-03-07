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

variable "alb_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to allow access to ALB"
  default     = []
}

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

variable "cdn_http_version" {
  type        = string
  default     = "http2"
  description = "The maximum HTTP version to support on the distribution. Allowed values are http1.1, http2, http2and3 and http3."
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
  description = "Whether to create a DNS alias of `app_dns_name`.`domain_name` to the ALB endpoint or not. For example, if an external CDN is used, or no CDN is used, this may be useful."
}

variable "create_cdn_dns_records" {
  type        = bool
  default     = true 
  description = "Whether to create DNS aliases of `app_dns_name`.`domain_name` and other aliases supplied in `app_dns_aliases` to the CDN endpoint or not."
}

variable "alb_dns_aliases" {
  type        = list(string)
  description = "A list of FQDN's (e.g. vanity domains, or domains that should not be served via CDN) to add as aliases to the ALB."
  default     = []
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

variable "app_dns_aliases" {
  type        = list(string)
  description = "A list of FQDN's (e.g. vanity domains) to add as aliases to the CDN. Ignored for ALB domains."
  default     = []
}

variable "alb_access_logs_s3_bucket_force_destroy" {
  type        = bool
  default     = true
  description = "A boolean that indicates all objects should be deleted from the ALB access logs S3 bucket so that the bucket can be destroyed without error"
}

variable "alb_https_ssl_policy" {
  type = string
  default = "ELBSecurityPolicy-TLS13-1-2-2021-06"
  description = "The name of the SSL Policy for the listener. Required if `https_enabled` is true."
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

variable "service_redeploy_on_apply" {
  type        = bool
  description = "Updates the service to the latest task definition on each apply"
  default     = false
}

variable "ecs_capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = optional(number, null)
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
  type        = map(string)
  description = "Map of policy name to IAM policy ARNs to attach to the ECS task role"
  default     = {}
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

variable "codepipeline_webhook_enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any webhook resources"
  default     = true
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

variable "codepipeline_add_queue_env_vars" {
  type        = bool
  description = "Add environment variables for queue names, region and prefix to CodeBuild project"
  default     = false
}

// CodePipeline notifications

variable "codepipeline_slack_notifications" {
  type = map(object({
    webhook_url  = string,
    channel      = string,
    event_groups = optional(list(string), ["all"]),
    event_ids    = optional(list(string), [])
  }))
  description = <<EOT
    Slack notification subscription details for receiving CodePipeline notifications.
    The map key is the name of the notification subscription.
    The intention of having multiple notification subscriptions is to direct different types of events
    to different Slack channels.
    Event groups are a convenience, instead of listing all the event IDs. Valid options for group
    are: 'all', 'errors', 'minimal'.
    If event_ids are specified they will be merged with the event groups list if it is supplied.
EOT
  default     = {}
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

variable "codebuild_policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the CodeBuild role"
  default     = []
}

// Queue

variable "queue_names" {
  type        = map(string)
  description = "Map of queue short name to full queue name of SQS queues used by application (if any). The item with key `app` will be set as the default queue for the application."
  default     = {}
}

// Buckets

variable "external_app_buckets" {
  type        = list(string)
  description = "Existing S3 buckets used by the application. Allows application and CodePipeline roles to access these buckets."
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
  default     = "TLSv1.2_2021"
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

# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/distribution-web-values-specify.html#DownloadDistValuesOriginKeepaliveTimeout
variable "cdn_origin_keepalive_timeout" {
  type        = number
  description = "The Custom KeepAlive timeout, in seconds. AWS defaults to 5 seconds. Values from 1-60s are supported, but a value above 60s requires a Support ticket."
  default     = 5
}

variable "cdn_origin_read_timeout" {
  type        = number
  description = "The Custom Read timeout, in seconds. AWS defaults to 30s. Values from 1-180s are supported, but a value above 60s requires a Support ticket."
  default     = 60
}

# https://docs.aws.amazon.com/AmazonCloudFront/latest/DeveloperGuide/secure-connections-supported-viewer-protocols-ciphers.html
variable "cdn_origin_ssl_protocols" {
  description = "The SSL/TLS protocols that you want CloudFront to use when communicating with your origin over HTTPS"
  type        = list(string)
  default     = ["TLSv1", "TLSv1.1", "TLSv1.2"]
}

variable "cdn_logging_enabled" {
  type        = bool
  default     = false
  description = "When true, access logs will be sent to a newly created s3 bucket"
}

variable "cdn_log_include_cookies" {
  type        = bool
  default     = false
  description = "Include cookies in access logs"
}

variable "cdn_log_prefix" {
  type        = string
  default     = ""
  description = "Path of logs in S3 bucket"
}

variable "cdn_log_bucket_fqdn" {
  type        = string
  default     = ""
  description = "Optional fqdn of logging bucket, if not supplied a bucket will be generated."
}

variable "cdn_log_force_destroy" {
  type        = bool
  description = "Applies to log bucket created by this module only. If true, all objects will be deleted from the bucket on destroy, so that the bucket can be destroyed without error. These objects are not recoverable."
  default     = false
}

variable "cdn_log_standard_transition_days" {
  type        = number
  description = "Number of days to persist in the standard storage tier before moving to the glacier tier"
  default     = 30
}

variable "cdn_log_glacier_transition_days" {
  type        = number
  description = "Number of days after which to move the data to the glacier storage tier"
  default     = 60
}

variable "cdn_log_expiration_days" {
  type        = number
  description = "Number of days after which to expunge the objects"
  default     = 90
}

variable "cdn_headers_response_security_referrer" {
  type        = string
  description = "The value of the referer header that CloudFront sends in the response. This will override the value from the origin."
  default     = "strict-origin-when-cross-origin"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_response_headers_policy#strict_transport_security
variable "cdn_headers_response_security_sts" {
  type        = object({
    access_control_max_age_sec            = number
      include_subdomains = bool
      preload           = bool
  })
  description = "Determines whether CloudFront includes the Strict-Transport-Security HTTP response header and the header's value. "
  default     = null
}

variable "cdn_headers_response_remove" {
  type       = list(string)
  description = "List of headers to remove from the response"
  default     = ["Server"]
}

variable "cdn_headers_response_custom" {
  type        = map(object({
    override  = bool
    header_value = string
  }))
  description = "Custom headers to add to the response with override flag"
  default     = null
}


// Front-end static website

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