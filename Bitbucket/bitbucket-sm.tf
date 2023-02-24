resource "random_string" "bitbucket_db_pass" {
  length           = 15
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%"
}

resource "random_string" "bitbucket_admin_pass" {
  length           = 15
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%"
}

resource "random_string" "svc_bitbucket_pass" {
  length           = 15
  special          = true
  min_lower        = 1
  min_upper        = 1
  min_numeric      = 1
  min_special      = 1
  override_special = "!#%"
}

resource "aws_secretsmanager_secret" "bitbucket_admin_credential" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}admin"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_admin_credential" {
  provider = aws.mgmt

  secret_id     = "${var.bitbucket_secrets_path}admin"
  secret_string = random_string.bitbucket_admin_pass.result
  depends_on    = [aws_secretsmanager_secret.bitbucket_admin_credential]
}

resource "aws_secretsmanager_secret" "bitbucket_admin_username" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}admin_username"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_admin_username" {
  provider = aws.mgmt

  secret_id     = "${var.bitbucket_secrets_path}admin_username"
  secret_string = "bitbucket"
  depends_on    = [aws_secretsmanager_secret.bitbucket_admin_username]
}

resource "aws_secretsmanager_secret" "bitbucket_db_name" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}bitbucket_db_name"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_db_name" {
  provider = aws.mgmt

  secret_id     = aws_secretsmanager_secret.bitbucket_db_name.id
  secret_string = "bitbucket"
}

resource "aws_secretsmanager_secret" "bitbucket_db_username" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}bitbucket_db_username"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_db_username" {
  provider = aws.mgmt

  secret_id     = aws_secretsmanager_secret.bitbucket_db_username.id
  secret_string = "bitbucket_admin"
}

resource "aws_secretsmanager_secret" "bitbucket_db_password" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}bitbucket_db_password"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_db_password" {
  provider = aws.mgmt

  secret_id     = aws_secretsmanager_secret.bitbucket_db_password.id
  secret_string = random_string.bitbucket_db_pass.result
}

resource "aws_secretsmanager_secret" "bitbucket_opensearch_master_username" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}bitbucket_opensearch_master_username"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_opensearch_master_username" {
  provider = aws.mgmt

  secret_id     = aws_secretsmanager_secret.bitbucket_opensearch_master_username.id
  secret_string = "opensearch_admin"
}

resource "aws_secretsmanager_secret" "bitbucket_opensearch_master_password" {
  provider = aws.mgmt

  name       = "${var.bitbucket_secrets_path}bitbucket_opensearch_master_password"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "bitbucket_opensearch_master_password" {
  provider = aws.mgmt

  secret_id     = aws_secretsmanager_secret.bitbucket_opensearch_master_password.id
  secret_string = random_string.bitbucket_db_pass.result
}

resource "aws_secretsmanager_secret" "svc_bitbucket" {
  provider = aws.mgmt

  name       = "${var.ad_secrets_path}svc_bitbucket"
  kms_key_id = data.terraform_remote_state.setup.outputs.secrets_manager_key_id
}

resource "aws_secretsmanager_secret_version" "svc_bitbucket" {
  provider = aws.mgmt

  secret_id     = "${var.ad_secrets_path}svc_bitbucket"
  secret_string = random_string.svc_bitbucket_pass.result
  depends_on    = [aws_secretsmanager_secret.svc_bitbucket]
}