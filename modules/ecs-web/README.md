# ecs-web

## Description

This module creates a web service on ECS, along with an ECR repository, a load balancer, and optionally a Codepipeline project to deploy it.

Another option is the creation of a CloudFront
distribution and S3 bucket from which to serve the frontend. In this scenario, it is assumed
that the main ECS web service is an API, with the frontend being a SPA website.

It is not possible to disable the ALB creation but it is possible to choose whether to add a DNS alias to it.

Broadly speaking, it depends on the following resources:

* VPC
* ECS cluster
* Route 53 zone

## Notes

### CloudFront

The module adds aliases for CloudFront for the app's FQDN and for any others supplied in the 
`app_dns_aliases` variable. These are required for properly configuring the distribution, including
accepted domains and CORS. The module can also create DNS records for these aliases, which point
to the CloudFront distribution. If a vanity domain from a zone other than the zone used for the 
ALB, DNS records creation should be disabled and these records created elsewhere.

### CodePipeline

When using a Codestar connection created by this module it is 
currently unfortunately necessary to do a targeted apply before creating the rest 
of the resources. This is to avoid an error by which a count condition depends on 
resources available after apply. This is a common issue with Terraform.

You must also manually verify the connection in the AWS console under CodePipeline -> Developer Tools -> Connections.

```shell
terraform apply -target='aws_codestarconnections_connection.default'
terraform apply
```