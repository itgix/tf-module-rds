################################################################################
# Serverless v2
################################################################################
resource "aws_kms_key" "rds" {
  description         = "RDS cluster encryption key"
  enable_key_rotation = true
}

#tfsec:ignore:aws-vpc-no-public-egress-sgr
module "aurora_serverless_v2" {
  source  = "cloudposse/rds-cluster/aws"
  version = "1.6.0"

  name           = var.rds_cluster_name == "" ? "rds-${local.name_string}" : var.rds_cluster_name
  engine         = var.rds_config.engine
  engine_mode    = var.rds_config.engine_mode
  engine_version = var.rds_config.engine_version
  cluster_family = var.rds_config.cluster_family
  db_port        = var.rds_config.db_port
  db_name        = var.rds_config.db_name

  ## Networking
  vpc_id          = var.rds_vpc_id
  subnets         = var.rds_subnets
  security_groups = var.rds_security_groups

  ## Encryption
  kms_key_arn       = aws_kms_key.rds.arn
  storage_encrypted = var.rds_storage_encrypted

  ## Provisioning
  cluster_size                       = var.rds_config.cluster_size
  serverlessv2_scaling_configuration = var.rds_scaling_config

  ## Authentication
  admin_user                          = var.rds_default_username
  admin_password                      = local.rds_credentials.password
  iam_database_authentication_enabled = var.rds_iam_auth_enabled

  ## Logs
  enabled_cloudwatch_logs_exports = var.rds_logs_exports

  ## Monitoring
  rds_monitoring_interval          = var.rds_monitoring_interval
  enhanced_monitoring_role_enabled = var.rds_monitoring_role_enabled

  ## Performance Insights
  performance_insights_enabled          = var.rds_performance
  performance_insights_kms_key_id       = aws_kms_key.rds.arn
  performance_insights_retention_period = var.rds_performance_retention
}
