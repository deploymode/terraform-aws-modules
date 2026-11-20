# DeployMode Terraform AWS Modules

Terraform modules for building and running applications on AWS. They cover account setup, IAM, DNS, networking, compute, data stores and monitoring.

The modules are opinionated. Their defaults and structure reflect the patterns we use in our client work, and many of them wrap the excellent and battle-tested [Cloud Posse](https://github.com/cloudposse) modules.

## Support

Open an [issue](https://github.com/deploymode/terraform-aws-modules/issues) or email support@deploymode.com.

## Release process

Every merge to `master` publishes a new GitHub release and tag, such as `v0.106.1`. [Release Drafter](https://github.com/release-drafter/release-drafter) creates the release from the merged pull requests.

Labels on the pull request decide the version and the release notes:

- **Version bump:** `major`, `minor` or `patch`. Without one of these labels, the release is a patch.
- **Release notes section:** `feature` or `enhancement` for Features, `fix`, `bugfix` or `bug` for Bug Fixes, and `chore` for Maintenance.

To merge without publishing a release, add the `no-release` label to the pull request. If you can't add a label, put `[no-release]` in the merge commit message.

Pin modules to a release tag, for example:

```hcl
source = "git::https://github.com/deploymode/terraform-aws-modules.git//modules/network?ref=v0.106.1"
```

## Modules

| Module | Summary |
| --- | --- |
| `account` | Creates an AWS Organization and its member accounts, and sets the account password policy. |
| `account-policies` | Creates account-wide IAM policies, usually for third-party services. |
| `account-roles` | Creates optional admin and DNS management roles in an account, assumable by the given principals. |
| `alarm-notifications` | Creates an SNS topic and subscriptions to deliver CloudWatch alarm notifications. |
| `app-buckets` | Creates S3 buckets for an application, with optional public paths and IAM policies for app and backup access. |
| `app-cache-dynamodb` | Creates a DynamoDB table for use as an application cache, plus an IAM policy to access it. |
| `app-cache-memcached` | Creates an ElastiCache Memcached cluster and a security group for allowed clients. |
| `app-cache-redis` | Creates an ElastiCache Redis cluster and a security group for allowed clients. |
| `betterstack-log-forwarder` | Forwards CloudWatch Logs to Better Stack. |
| `certs` | Creates and DNS-validates an ACM certificate in an existing hosted zone. |
| `cost-alerts` | Creates AWS Budgets and Cost Anomaly Detection alerts, delivered through SNS. |
| `db` | Creates an RDS instance with an optional read replica, a security group, and credentials stored in SSM Parameter Store. |
| `db-cluster` | Creates an RDS cluster, a security group, and credentials stored in SSM Parameter Store. |
| `dns-delegated` | Creates a subdomain zone and delegates it from the primary zone, for example `staging.example.net`. |
| `dns-primary` | Creates the primary DNS zone for a domain, with DNSSEC support, to delegate to other accounts. |
| `eb-app` | Creates an Elastic Beanstalk application and environment, with optional SSH key pair and settings stored in SSM. |
| `ec2-bastion` | Creates an EC2 bastion host and its key pair. |
| `ecs-background` | Creates an ECS service or scheduled task for background work, with an ECR repository, autoscaling and an optional CodePipeline deployment. |
| `ecs-cluster` | Creates an ECS cluster with capacity providers and a private service discovery namespace. |
| `ecs-event-logs` | Captures ECS events with EventBridge and writes them to CloudWatch Logs. |
| `ecs-web` | Creates an ECS web service with an ECR repository and load balancer, plus optional CodePipeline deployment and a CloudFront-hosted frontend. |
| `email` | Sets up SES for a domain, with DNS records, SNS notification topics and an IAM role for sending email. |
| `external-role` | Creates an IAM role that a third-party AWS account can assume, with an optional external ID. |
| `github-oidc-ecr` | Lets GitHub Actions push to ECR through an OIDC-federated IAM role. |
| `iam` | Creates IAM users and groups in the master account whose only permission is to assume roles in other accounts. |
| `iam-single-account` | Creates IAM users, groups and assumable roles for a single-account setup. |
| `load-balancer` | Creates an Application Load Balancer with a DNS record, and an optional CloudFront and S3 CDN. |
| `log-settings` | Sets the retention period on existing CloudWatch log groups. |
| `network` | Creates a VPC with public and private subnets, an optional NAT gateway or NAT instance, and an optional S3 gateway endpoint. |
| `queue` | Creates an SQS queue and an IAM policy to access it. |
| `s3-replication` | Creates a destination S3 bucket and the IAM role and policies to replicate a source bucket into it. |
| `vpc-endpoints` | Creates VPC interface endpoints for ECR, CloudWatch Logs and SSM. |
