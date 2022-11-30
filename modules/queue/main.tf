// SQS
data "aws_iam_policy_document" "sqs" {
  count = module.this.enabled ? 1 : 0

  # Policy to allow access to queue messages
  statement {
    sid = ""

    # principals {
    #   type        = "AWS"
    #   identifiers = var.roles_for_queue_access
    # }

    actions = [
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:GetQueueUrl",
      "sqs:DeleteMessage",
      "sqs:ChangeMessageVisibility"
    ]

    resources = module.queue.*.sqs_queue_arn

    effect = "Allow"
  }
}

resource "aws_iam_policy" "sqs_policy" {
  count       = module.this.enabled ? 1 : 0
  name        = module.this.id
  path        = "/"
  description = "Allow access to queue messages in ${module.this.id}"
  policy      = join("", data.aws_iam_policy_document.sqs.*.json)
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = ">= 3.0"

  for_each = var.queues

  create                      = module.this.enabled && each.value.enabled
  name                        = "${module.this.id}-${each.key}"
  visibility_timeout_seconds  = each.value.visibility_timeout_seconds
  fifo_queue                  = each.value.fifo_queue
  deduplication_scope         = each.value.deduplication_scope
  content_based_deduplication = each.value.content_based_deduplication
  message_retention_seconds   = each.value.message_retention_seconds

  tags = module.this.tags
}
