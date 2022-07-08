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

variable "subnet_ids" {
  type        = list(string)
  description = "List of subnet IDs - public or private. When choosing public you can also specific that a public IP is assigned."
}

// ECR

variable "ecr_max_image_count" {
  type        = number
  description = "Maximum number of images to store before ECR lifecycle rules delete oldest"
  default     = 500
}

// ECS


variable "ecs_security_group_ids" {
  type        = list(string)
  description = "Additional Security Group IDs to assign to ECS Service"
  default     = []
}

variable "ecs_enable_exec" {
  type        = bool
  description = "Specifies whether to enable Amazon ECS Exec for the tasks within the service. Creates required IAM policies."
  default     = false
}

variable "allowed_ingress_security_group_ids" {
  type        = list(string)
  description = "Security Group IDs for which to allow ingress to ECS Service"
  default     = []
}

variable "ecs_task_policy_arns" {
  type        = list(string)
  description = "List of IAM policy ARNs to attach to the ECS task role"
  default     = []
}

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

variable "ecs_capacity_provider_strategies" {
  type = list(object({
    capacity_provider = string
    weight            = number
    base              = number
  }))
  description = "The capacity provider strategies to use for the service. See `capacity_provider_strategy` configuration block: https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy"
  default     = []
}

variable "service_force_new_deployment" {
  type        = bool
  description = "Enable to force a new task deployment of the service."
  default     = false
}

variable "service_discovery_private_dns_namespace_id" {
  type        = string
  description = "The service discovery private DNS namespace ID"
  default     = null
}

variable "use_service_discovery" {
  type        = bool
  description = "If true, add a service discovery service resource"
  default     = false
}

variable "ecs_ignore_changes_task_definition" {
  type        = bool
  description = "Whether to ignore changes in container definition and task definition in the ECS service"
  default     = false
}



// ECS Task Variables

variable "ecs_network_mode" {
  type        = string
  default     = "awsvpc"
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


variable "assign_public_ip" {
  type        = bool
  description = "Should containers have public IPs assigned? Setting this to true avoids needing a NAT gateway."
  default     = false
}

// Container variables

variable "log_driver" {
  type        = string
  description = "Docker log driver"
  default     = "awslogs"
}

variable "ssm_param_store_app_key" {
  type        = string
  default     = "app"
  description = "App-level key in SSM Parameter Store path"
}

// Container

variable "container_image" {
  type        = string
  description = "Docker registry image name (and tag). If not specified, ECR is used."
  default     = null
}

variable "container_command" {
  type        = list(string)
  description = "The command that is passed to the container"
  default     = null
}

variable "container_entrypoint" {
  type        = list(string)
  description = "The entry point that is passed to the container"
  default     = null
}

variable "container_cpu" {
  type        = number
  description = "CPU limit for container"
  default     = 512
}

variable "container_memory" {
  type        = number
  description = "Hard memory limit"
  default     = 256
}

variable "container_memory_reservation" {
  type        = number
  description = "Soft memory limit"
  default     = 128
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Container environment variables for containers"
  default     = null
}

variable "container_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container. This is a list of maps"
  default     = null
}

variable "container_port_mappings" {
  type = list(object({
    containerPort = number
    hostPort      = number
    protocol      = string
  }))

  description = "The port mappings to configure for the container. This is a list of maps. Each map should contain \"containerPort\", \"hostPort\", and \"protocol\", where \"protocol\" is one of \"tcp\" or \"udp\". If using containers in a task with the awsvpc or host network mode, the hostPort can either be left blank or set to the sa0 value as the containerPort"

  default = [
    # {
    #   containerPort = 80
    #   hostPort      = 80
    #   protocol      = "tcp"
    # }
  ]
}

variable "container_port" {
  type        = number
  description = "The port on the container to allow via the ingress security group"
  default     = 80
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

// CodePipeline

variable "codestar_connection_arn" {
  type        = string
  description = "Bitbucket connection"
  default     = ""
}

variable "codepipeline_skip_deploy_step" {
  type        = bool
  description = "When true Deploy step will not be added in CodePipeline"
  default     = false
}

variable "github_anonymous" {
  type        = bool
  description = "Github Anonymous API (if `true`, token must not be set as GITHUB_TOKEN or `github_token`)"
  default     = false
}

variable "codepipeline_github_oauth_token" {
  type        = string
  description = "GitHub OAuth Token with permissions to access private repositories"
  default     = ""
}

variable "codepipeline_github_webhooks_token" {
  type        = string
  default     = ""
  description = "GitHub OAuth Token with permissions to create webhooks. If not provided, can be sourced from the `GITHUB_TOKEN` environment variable"
}

variable "codepipeline_github_webhook_events" {
  type        = list(string)
  description = "A list of events which should trigger the webhook. See a list of [available events](https://developer.github.com/v3/activity/events/types/)"
  default     = ["push"]
}

variable "codepipeline_github_webhook_enabled" {
  type        = bool
  description = "Set to false to prevent the module from creating any webhook resources"
  default     = true
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

variable "codepipeline_build_compute_type" {
  type        = string
  default     = "BUILD_GENERAL1_SMALL"
  description = "`CodeBuild` instance size. Possible values are: `BUILD_GENERAL1_SMALL` `BUILD_GENERAL1_MEDIUM` `BUILD_GENERAL1_LARGE`"
}

variable "codepipeline_build_timeout" {
  type        = number
  default     = 60
  description = "How long in minutes, from 5 to 480 (8 hours), for AWS CodeBuild to wait until timing out any related build that does not get marked as completed"
}

variable "codepipeline_buildspec" {
  type        = string
  default     = ""
  description = "Declaration to use for building the project or a path to an alternate buildspec.yml file. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html)"
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

// CodeBuild


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

// Queue

variable "queue_name" {
  type        = string
  description = "Name of SQS queue used by application (if any)"
  default     = ""
}

variable "dynamodb_table_name" {
  type        = string
  description = "Name of DynamoDB table used by application (if any)"
  default     = ""
}


