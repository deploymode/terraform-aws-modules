// SQS
data "aws_iam_policy_document" "sqs" {
  count = (module.this.enabled && length(var.roles_for_queue_access) > 0) ? 1 : 0

  # Allow specified roles to access queue messages
  statement {
    sid = ""

    principals {
      type        = "AWS"
      identifiers = var.roles_for_queue_access
    }

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl"
    ]

    resources = [
      module.queue.this_sqs_queue_arn
    ]

    effect = "Allow"
  }
}

resource "aws_sqs_queue_policy" "sqs" {
  count     = (module.this.enabled && length(var.roles_for_queue_access) > 0) ? 1 : 0
  queue_url = module.queue.this_sqs_queue_id
  policy    = join("", data.aws_iam_policy_document.sqs.*.json)
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = ">= 2.0"
  create  = module.this.enabled
  name    = module.this.name
  tags    = module.this.tags
}
