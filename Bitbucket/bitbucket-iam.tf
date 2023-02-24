data "aws_iam_policy_document" "bitbucket_policy" {
  provider = aws.mgmt

  statement {
    sid    = "AllowEC2CreateTags"
    effect = "Allow"
    actions = [
      "ec2:DescribeTags",
      "ec2:CreateTags"
    ]
    resources = ["*"]
  }

  statement {
    sid    = "AllowRDSReboot"
    effect = "Allow"
    actions = [
      "rds:RebootDBInstance",
      "rds:DescribeDBInstances"
    ]
    resources = [module.bitbucket-db.db_instance_arn]
  }

  statement {
    sid    = "AllowInstallBucketPermissions"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:ListBucketMultipartUploads",
      "s3:ListBucketVersions",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
      "s3:AbortMultipartUpload",
      "s3:ListMultipartUploadParts"
    ]
    resources = ["arn:${var.partition}:s3:::${data.terraform_remote_state.setup.outputs.install_bucket_name}/bitbucket"]
  }

  statement {
    sid    = "AllowGetSecretsRootCA"
    effect = "Allow"
    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds",
      "secretsmanager:ListSecrets"
    ]
    resources = [
      "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}root_ca_pub.pem*",
      "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bitbucket_cert*",
      "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bitbucket_cert_key*",
      "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bitbucket_opensearch_cert*",
      "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bitbucket_opensearch_certkey*",
      #Uncomment if using other Atlassian tools
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}jira1_cert*",
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}jira1_cert_key*",
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}confluence_cert*",
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}confluence_cert_key*",
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bamboo_cert*",
      # "arn:${var.partition}:secretsmanager:${var.aws_region}:${local.mgmt_account_id}:secret:${var.ca_secrets_rootca_path}bamboo_cert_key*"
    ]
  }

  statement {
    sid    = "AllowOpensearch"
    effect = "Allow"
    actions = [
      "es:ESHttpHead",
      "es:ESHttpPost",
      "es:ESHttpGet",
      "es:ESHttpPatch",
      "es:DescribeDomain",
      "es:ESHttpDelete",
      "es:ESHttpPut"
    ]
    resources = [aws_opensearch_domain.bitbucket-opensearch-domain.arn]
  }
}

resource "aws_iam_policy" "bitbucket_policy" {
  provider = aws.mgmt

  name   = "bitbucket_policy"
  policy = data.aws_iam_policy_document.bitbucket_policy.json
}
