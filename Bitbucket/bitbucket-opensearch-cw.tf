resource "aws_cloudwatch_log_group" "opensearch-cloudwatch-log-group" {
  provider          = aws.mgmt
  name              = "/aws/opensearch/instance/bitbucket"
  retention_in_days = 0
  kms_key_id        = data.terraform_remote_state.setup.outputs.opensearch_key_arn
}

data "aws_iam_policy_document" "opensearch-log-publishing-policy" {
  statement {
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:PutLogEventsBatch",
    ]

    resources = ["arn:aws-us-gov:logs:*"]

    principals {
      identifiers = ["opensearchservice.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_cloudwatch_log_resource_policy" "opensearch-log-publishing-policy" {
  policy_document = data.aws_iam_policy_document.opensearch-log-publishing-policy.json
  policy_name     = "opensearch-log-publishing-policy"
}
