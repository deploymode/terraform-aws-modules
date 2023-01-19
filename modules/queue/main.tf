// SQS
data "aws_iam_policy_document" "sqs" {
  for_each = module.this.enabled ? var.queues : {}

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

    resources = [module.queue[each.key].queue_arn]

    effect = "Allow"
  }
}

resource "aws_iam_policy" "sqs_policy" {
  for_each    = module.this.enabled ? var.queues : {}
  name        = "${module.this.id}-${each.key}"
  path        = "/"
  description = "Allow access to queue messages in ${module.this.id}-${each.key}"
  policy      = data.aws_iam_policy_document.sqs[each.key].json
}

module "queue" {
  source  = "terraform-aws-modules/sqs/aws"
  version = ">= 4.0"

  for_each = module.this.enabled ? var.queues : {}

  create                      = module.this.enabled && each.value.enabled
  name                        = coalesce(each.value.name, "${module.this.id}-${each.key}")
  visibility_timeout_seconds  = each.value.visibility_timeout_seconds
  fifo_queue                  = each.value.fifo_queue
  deduplication_scope         = each.value.fifo_queue ? each.value.deduplication_scope : null
  content_based_deduplication = each.value.content_based_deduplication
  message_retention_seconds   = each.value.message_retention_seconds

  tags = module.this.tags
}
