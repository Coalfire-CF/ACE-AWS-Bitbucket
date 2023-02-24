resource "aws_iam_service_linked_role" "bitbucket_opensearch_service_linked_role" {
  provider         = aws.mgmt
  aws_service_name = "opensearchservice.amazonaws.com"
}

resource "aws_opensearch_domain" "bitbucket-opensearch-domain" {
  provider = aws.mgmt

  domain_name    = "${var.resource_prefix}-bitbucket"
  engine_version = "OpenSearch_1.2"

  ebs_options {
    ebs_enabled = true
    volume_size = 50
    volume_type = "gp2"

  }

  cluster_config {
    instance_type            = "c5.xlarge.search"
    instance_count           = 1
    zone_awareness_enabled   = false #This prevents multi-az so you can limit to 1 node.
    dedicated_master_enabled = false
  }

  domain_endpoint_options {
    custom_endpoint_certificate_arn = aws_acm_certificate.bitbucket-opensearch-cert.arn
    custom_endpoint_enabled         = true
    custom_endpoint                 = "bitbucket-opensearch.imatchinternal.org"
    enforce_https                   = true
    tls_security_policy             = "Policy-Min-TLS-1-2-2019-07"
  }

  encrypt_at_rest {
    enabled    = true
    kms_key_id = data.terraform_remote_state.setup.outputs.opensearch_key_id
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch-cloudwatch-log-group.arn
    enabled                  = true
    log_type                 = "INDEX_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch-cloudwatch-log-group.arn
    enabled                  = true
    log_type                 = "SEARCH_SLOW_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch-cloudwatch-log-group.arn
    enabled                  = true
    log_type                 = "ES_APPLICATION_LOGS"
  }

  log_publishing_options {
    cloudwatch_log_group_arn = aws_cloudwatch_log_group.opensearch-cloudwatch-log-group.arn
    enabled                  = true
    log_type                 = "AUDIT_LOGS"
  }

  node_to_node_encryption {
    enabled = true
  }

  snapshot_options {
    automated_snapshot_start_hour = 0
  }

  vpc_options {
    subnet_ids = [
      data.terraform_remote_state.network-mgmt.outputs.private_subnets[6]
    ]

    security_group_ids = [aws_security_group.bitbucket_opensearch_sg.id]
  }

  auto_tune_options {
    desired_state       = "DISABLED"
    rollback_on_disable = "DEFAULT_ROLLBACK"
  }

  advanced_security_options {
    enabled                        = true
    internal_user_database_enabled = true

    master_user_options {
      master_user_name     = aws_secretsmanager_secret_version.bitbucket_opensearch_master_username.secret_string
      master_user_password = aws_secretsmanager_secret_version.bitbucket_opensearch_master_password.secret_string
    }
  }

  depends_on = [aws_iam_service_linked_role.bitbucket_opensearch_service_linked_role]

}
data "aws_secretsmanager_secret_version" "rootca" {
  provider = aws.mgmt

  secret_id = "${var.ca_secrets_rootca_path}${var.root_ca_pub_cert}"
}

resource "aws_acm_certificate" "bitbucket-opensearch-cert" {
  provider = aws.mgmt

  private_key       = data.aws_secretsmanager_secret_version.bitbucket_opensearch_certkey.secret_string
  certificate_body  = data.aws_secretsmanager_secret_version.bitbucket_opensearch_cert.secret_string
  certificate_chain = data.aws_secretsmanager_secret_version.rootca.secret_string
}

data "aws_secretsmanager_secret_version" "bitbucket_opensearch_cert" {
  provider = aws.mgmt

  secret_id = "${var.ca_secrets_rootca_path}${var.bitbucket_opensearch_cert}"
}

data "aws_secretsmanager_secret_version" "bitbucket_opensearch_certkey" {
  provider = aws.mgmt

  secret_id = "${var.ca_secrets_rootca_path}${var.bitbucket_opensearch_certkey}"
}

resource "aws_opensearch_domain_policy" "bitbucket_opensearch_domain" {
  domain_name = aws_opensearch_domain.bitbucket-opensearch-domain.domain_name

  access_policies = <<POLICIES
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": ["es:*"],
            "Principal": "*",
            "Effect": "Allow",
            "Resource": "${aws_opensearch_domain.bitbucket-opensearch-domain.arn}/*"
        }
    ]
}
POLICIES
}


