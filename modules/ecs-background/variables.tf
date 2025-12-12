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

variable "ecr_force_delete" {
  type        = bool
  description = "Force delete ECR repository if it contains images"
  default     = true
}

variable "ecr_image_tag_mutability" {
  type        = string
  description = "ECR image tag mutability. Valid values: IMMUTABLE, MUTABLE"
  default     = "MUTABLE"
}

// ECS

variable "ecs_service_enabled" {
  type        = bool
  description = "Whether or not to create the ECS service"
  default     = true
}

variable "create_run_task_role" {
  type        = bool
  description = "Whether to create an IAM policy to allow running the task via RunTask"
  default     = false
}

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
  type        = map(string)
  description = "Map of name to IAM policy ARNs to attach to the ECS task role"
  default     = {}
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
    base              = optional(number, null)
  }))
  description = <<EOT
    The capacity provider strategies to use for the service.
    See `capacity_provider_strategy` configuration block: 
    https://www.terraform.io/docs/providers/aws/r/ecs_service.html#capacity_provider_strategy

    Note, setting a weight of 0 will effectively disable the capacity
    provider.
EOT
  default     = []
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

variable "ecs_task_def_track_latest" {
  type        = bool
  description = "Track the latest revision of the task definition rather than only the revisions managed by Terraform."
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

variable "container_overrides" {
  type = object({
    command = optional(list(string))
    cpu     = optional(number)
    dependsOn = optional(list(object({
      condition     = string
      containerName = string
    })))
    disableNetworking     = optional(bool)
    dnsSearchDomains      = optional(list(string))
    dnsServers            = optional(list(string))
    dockerLabels          = optional(map(string))
    dockerSecurityOptions = optional(list(string))
    entryPoint            = optional(list(string))
    environment = optional(list(object({
      name  = string
      value = string
    })))
    environmentFiles = optional(list(object({
      type  = string
      value = string
    })))
    essential = optional(bool)
    extraHosts = optional(list(object({
      hostname  = string
      ipAddress = string
    })))
    firelensConfiguration = optional(object({
      options = optional(map(string))
      type    = string
    }))
    healthCheck = optional(object({
      command     = list(string)
      interval    = optional(number)
      retries     = optional(number)
      startPeriod = optional(number)
      timeout     = optional(number)
    }))
    hostname    = optional(string)
    image       = optional(string)
    interactive = optional(bool)
    links       = optional(list(string))
    linuxParameters = optional(object({
      capabilities = optional(object({
        add  = optional(list(string))
        drop = optional(list(string))
      }))
      devices = optional(list(object({
        containerPath = string
        hostPath      = string
        permissions   = optional(list(string))
      })))
      initProcessEnabled = optional(bool)
      maxSwap            = optional(number)
      sharedMemorySize   = optional(number)
      swappiness         = optional(number)
      tmpfs = optional(list(object({
        containerPath = string
        mountOptions  = optional(list(string))
        size          = number
      })))
    }))
    logConfiguration = optional(object({
      logDriver = string
      options   = optional(map(string))
      secretOptions = optional(list(object({
        name      = string
        valueFrom = string
      })))
    }))
    memory            = optional(number)
    memoryReservation = optional(number)
    mountPoints = optional(list(object({
      containerPath = optional(string)
      readOnly      = optional(bool)
      sourceVolume  = optional(string)
    })))
    name = optional(string)
    portMappings = optional(list(object({
      containerPort = number
      hostPort      = optional(number)
      protocol      = optional(string)
      name          = optional(string)
      appProtocol   = optional(string)
    })))
    privileged             = optional(bool)
    pseudoTerminal         = optional(bool)
    readonlyRootFilesystem = optional(bool)
    repositoryCredentials = optional(object({
      credentialsParameter = string
    }))
    resourceRequirements = optional(list(object({
      type  = string
      value = string
    })))
    restartPolicy = optional(object({
      enabled              = bool
      ignoredExitCodes     = optional(list(number))
      restartAttemptPeriod = optional(number)
    }))
    secrets = optional(list(object({
      name      = string
      valueFrom = string
    })))
    startTimeout = optional(number)
    stopTimeout  = optional(number)
    systemControls = optional(list(object({
      namespace = string
      value     = string
    })))
    ulimits = optional(list(object({
      hardLimit = number
      name      = string
      softLimit = number
    })))
    user               = optional(string)
    versionConsistency = optional(string)
    volumesFrom = optional(list(object({
      readOnly        = optional(bool)
      sourceContainer = string
    })))
    workingDirectory = optional(string)
  })
  description = "Container definition overrides which allows for extra keys or overriding existing keys."
  default     = {}
}

variable "container_image" {
  type        = string
  description = "A Docker registry image name (and tag). If not specified, ECR is used."
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
  default     = 0
  validation {
    condition     = var.container_cpu >= 0
    error_message = "Container CPU must be greater than or equal to 0. Use 0 to use the default CPU value of the task definition."
  }
}

variable "container_memory" {
  type        = number
  description = "Hard memory limit"
  default     = null
  validation {
    condition = var.container_memory == null || coalesce(var.container_memory, 0) >= 0
    # Coalesce is used to make the second clause evaluate to true if the value is null
    error_message = "Container memory must be greater than or equal to 0. Use null to use the default memory value of the task definition."
  }
}

variable "container_memory_reservation" {
  type        = number
  description = "Soft memory limit"
  default     = null
  validation {
    condition     = var.container_memory_reservation == null || coalesce(var.container_memory_reservation, 0) >= 0
    error_message = "Container memory reservation must be greater than or equal to 0. Use null to use the default memory reservation value of the task definition."
  }
}

variable "container_environment" {
  type = list(object({
    name  = string
    value = string
  }))
  description = "Container environment variables for containers"
  default     = null
}

variable "container_ssm_secrets" {
  type = list(object({
    name      = string
    valueFrom = string
  }))
  description = "The secrets to pass to the container. This is a list of maps"
  default     = null
}

variable "container_healthcheck" {
  type = object({
    command     = list(string)
    retries     = number
    timeout     = number
    interval    = number
    startPeriod = number
  })
  description = "Container healthcheck configuration for container. Set to null to disable."
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

variable "codepipeline_enabled" {
  type        = bool
  description = "When true, enables CodePipeline"
  default     = false
}

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

variable "codepipeline_github_oauth_token" {
  type        = string
  description = "GitHub OAuth Token with permissions to access private repositories"
  default     = ""
}

variable "codepipeline_github_webhook_events" {
  type        = list(string)
  description = "A list of events which should trigger the webhook. See a list of [available events](https://developer.github.com/v3/activity/events/types/)"
  default     = ["push"]
}

variable "codepipeline_webhook_enabled" {
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

// CodeBuild

variable "codebuild_cache_type" {
  type        = string
  default     = "S3"
  description = "The type of storage that will be used for the AWS CodeBuild project cache. Valid values: NO_CACHE, LOCAL, and S3.  Defaults to S3.  If cache_type is S3, it will create an S3 bucket for storing codebuild cache inside"
}

variable "codebuild_local_cache_modes" {
  type        = list(string)
  default     = ["LOCAL_SOURCE_CACHE"]
  description = "Specifies settings that AWS CodeBuild uses to store and reuse build dependencies. Valid values: LOCAL_SOURCE_CACHE, LOCAL_DOCKER_LAYER_CACHE, and LOCAL_CUSTOM_CACHE"
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project#vpc_config
variable "codebuild_vpc_config" {
  type        = any
  default     = {}
  description = "Configuration for the builds to run inside a VPC."
}

// Queue

variable "queue_names" {
  type        = map(string)
  description = "Map of queue short name to full queue name of SQS queues used by application (if any). The item with key `app` will be set as the default queue for the application."
  default     = {}
}

// Scheduling

variable "schedule_description" {
  description = "A description of the scheduled task. This is used to identify the task in the AWS console."
  type        = string
  default     = null
}

variable "schedule_expression" {
  description = "The scheduling expression. For example, cron(0 20 * * ? *) or rate(5 minutes)."
  type        = string
  default     = null
}

variable "schedule_expression_timezone" {
  description = "The timezone for the schedule expression. Defaults to UTC."
  type        = string
  default     = "UTC"
}

variable "scheduled_task_count" {
  description = "The number of tasks to run on each schedule. Defaults to 1."
  type        = number
  default     = 1
}
