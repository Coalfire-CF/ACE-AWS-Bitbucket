locals {
  name = "bitbucket"
  tags = {
    Name     = "bitbucket"
    OSFamily = "Postgres"
    OSType   = "Linux"
    App      = "Management"
  }
}


module "bitbucket-db" {
  providers = {
    aws = aws.mgmt
  }

  source = "../../../../modules/aws-rds"

  identifier = local.name

  engine                = "postgres"
  engine_version        = "12.12"
  family                = "postgres12"
  instance_class        = "db.t3.large"
  allocated_storage     = "100"
  max_allocated_storage = "1000"
  storage_type          = "gp2"
  storage_encrypted     = true
  kms_key_id            = data.terraform_remote_state.setup.outputs.rds_key_arn

  name     = aws_secretsmanager_secret_version.bitbucket_db_name.secret_string
  username = aws_secretsmanager_secret_version.bitbucket_db_username.secret_string
  password = aws_secretsmanager_secret_version.bitbucket_db_password.secret_string
  port     = "5432"

  vpc_security_group_ids = compact(concat([aws_security_group.bitbucket_db_sg.id]))
  subnet_ids = [
    data.terraform_remote_state.network-mgmt.outputs.private_subnets[4],
    data.terraform_remote_state.network-mgmt.outputs.private_subnets[5]
  ]
  parameter_group_name = "${var.resource_prefix}-${local.name}"
  db_subnet_group_name = ""

  multi_az               = "true"
  create_monitoring_role = true
  monitoring_interval    = 1
  monitoring_role_name   = "bitbucket_monitoring_role"

  allow_major_version_upgrade = "false"
  auto_minor_version_upgrade  = "false"
  apply_immediately           = "true"
  maintenance_window          = "Mon:00:00-Mon:03:00"
  skip_final_snapshot         = "true"
  copy_tags_to_snapshot       = "true"
  final_snapshot_identifier   = "bitbucket-final-snapshot"

  backup_retention_period = "35"
  backup_window           = "09:46-10:16"

  enabled_cloudwatch_logs_exports = ["postgresql", "upgrade"]

  deletion_protection = true

  tags = merge(
    local.tags,
    var.regional_tags,
    var.global_tags,
  )
  db_subnet_group_tags = {
    "backup_policy" = var.backup_policy
  }
}
