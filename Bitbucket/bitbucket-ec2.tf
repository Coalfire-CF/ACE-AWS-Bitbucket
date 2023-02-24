data "aws_ami" "rhel_gold_ami" {
  most_recent = true
  owners      = ["self"]
  provider    = aws.mgmt

  filter {
    name   = "name"
    values = ["rhel8-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

locals {
  db_instance_endpoint = element(split(":", module.bitbucket-db.db_instance_endpoint), 0)
}

module "bitbucket" {
  providers = {
    aws = aws.mgmt
  }

  source            = "../../../../modules/aws-ec2"
  name              = "bitbucket"
  instance_count    = 1
  ami               = data.aws_ami.rhel_gold_ami.id
  ec2_instance_type = "c5.xlarge"
  ec2_key_pair      = var.key_name
  root_volume_size  = "50"
  subnet_ids        = [data.terraform_remote_state.network-mgmt.outputs.private_subnets[4]]
  vpc_id            = data.terraform_remote_state.network-mgmt.outputs.vpc_id
  ebs_kms_key_arn   = data.terraform_remote_state.setup.outputs.ebs_key_arn

  iam_policies = [
    aws_iam_policy.bitbucket_policy.id,
    data.terraform_remote_state.setup.outputs.base_iam_policy_arn
  ]
  keys_to_grant = [
    data.terraform_remote_state.setup.outputs.s3_key_arn,
    data.terraform_remote_state.setup.outputs.secrets_manager_key_arn
  ]

  tags = {
    OSFamily = "RHEL8",
    OSType   = "Linux",
    App      = "Management",
    Backup   = var.backup_policy
  }

  additional_security_groups = [
    aws_security_group.bitbucket_instance_sg.id,
    data.terraform_remote_state.network-mgmt.outputs.base_mgmt_linux_sg_id,
    data.terraform_remote_state.jira.outputs.jira_app_links_sg
  ]
  cidr_security_group_rules = []

  user_data = [
    {
      path = {
        folder_name = "linux",
        file_name   = "ud-os-join-ad.sh"
      },
      vars = {
        aws_region            = var.aws_region,
        domain_name           = var.domain_name,
        dom_disname           = var.dom_disname,
        ou_env                = var.lin_prod_ou_env,
        linux_admins_ad_group = var.linux_admins_ad_group,
        domain_join_user_name = var.domain_join_user_name,
        sm_djuser_path        = "${var.ad_secrets_path}${var.domain_join_user_name}",
        is_asg                = "false",
      }
    },
    {
      path = {
        folder_name = "linux",
        file_name   = "ud-rds-pgaudit.sh"
      },
      vars = {
        db_instance_endpoint = local.db_instance_endpoint,
        identifier           = "bitbucket",
        db_port              = "5432"
        aws_region           = var.aws_region,
        db_password_path     = "${var.bitbucket_secrets_path}bitbucket_db_password",
        db_username          = module.bitbucket-db.db_instance_username,
        db_name              = module.bitbucket-db.db_instance_name,
        db_endpoint          = module.bitbucket-db.endpoint
      }
    },
    {
      path = {
        folder_name = "linux",
        file_name   = "ud-bitbucket-install.sh"
      },
      vars = {
        aws_region          = var.aws_region,
        domain_name         = var.domain_name,
        bitbucket_dl_url    = "https://www.atlassian.com/software/stash/downloads/binary/atlassian-bitbucket-7.21.10-x64.bin"
        bitbucket_version   = "7.21.10"
        username            = aws_secretsmanager_secret_version.bitbucket_admin_username.secret_string,
        password            = aws_secretsmanager_secret_version.bitbucket_admin_credential.secret_string,
        db_username         = aws_secretsmanager_secret_version.bitbucket_db_username.secret_string,
        db_password         = aws_secretsmanager_secret_version.bitbucket_db_password.secret_string,
        db_username         = module.bitbucket-db.db_instance_username,
        db_name             = module.bitbucket-db.db_instance_name,
        db_endpoint         = module.bitbucket-db.db_instance_endpoint,
        opensearch_url      = aws_opensearch_domain.bitbucket-opensearch-domain.endpoint,
        opensearch_password = aws_secretsmanager_secret_version.bitbucket_opensearch_master_password.secret_string,
        opensearch_username = aws_secretsmanager_secret_version.bitbucket_opensearch_master_username.secret_string
      }
    }
  ]

  sg_security_group_rules = []
  cidr_group_rules        = []
  global_tags             = var.global_tags
  regional_tags           = var.regional_tags
}
