module "dynamodb_label" {
  source     = "cloudposse/label/null"
  version    = "0.25.0"
  attributes = ["dynamodb"]
  context    = module.this.context
}

module "dynamodb" {
  source  = "cloudposse/dynamodb/aws"
  version = "0.35.0"

  hash_key                      = "key"
  enable_autoscaler             = false
  enable_point_in_time_recovery = false
  billing_mode                  = "PAY_PER_REQUEST"
  ttl_attribute                 = var.dynamodb_cache_ttl_attribute

  context = module.dynamodb_label.context
}

data "aws_iam_policy_document" "dynamodb" {
  # Allow ECS task to access DynamoDB cache table
  statement {
    sid = ""

    actions = [
      "dynamodb:DescribeTable",
      "dynamodb:Query",
      "dynamodb:Scan",
      "dynamodb:BatchGetItem",
      "dynamodb:BatchWriteItem",
      "dynamodb:ConditionCheckItem",
      "dynamodb:PutItem",
      "dynamodb:DeleteItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem"
    ]

    resources = [
      module.dynamodb.table_arn
    ]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "dynamodb_access_policy" {
  name        = module.dynamodb_label.id
  path        = "/"
  description = "Allows access to DynamoDB table for app cache"
  policy      = data.aws_iam_policy_document.dynamodb.json
}
