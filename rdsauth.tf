## Create secret
resource "random_password" "dbpass" {
  length  = 32
  special = false
}

resource "aws_kms_key" "rds_secret_kms_key" {
  description         = "KMS key to be used to encrypt the RDS secret values"
  enable_key_rotation = true
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Full Access for root account"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_account_id}:root"
        }
        Action   = ["kms:*"]
        Resource = "*"
      },
    ]
  })
}

resource "aws_kms_alias" "rds_secret_kms_key_alias" {
  name          = "alias/${local.name_string}_rds_secret_key"
  target_key_id = aws_kms_key.rds_secret_kms_key.key_id
}

resource "aws_secretsmanager_secret" "dbsecret" {
  description = "RDS credentials"
  name        = "rds-${local.name_string}"
  kms_key_id  = aws_kms_key.rds_secret_kms_key.arn

  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "dbsecret_version" {
  secret_id     = aws_secretsmanager_secret.dbsecret.id
  secret_string = <<EOF
  {
    "username": "${var.rds_default_username}",
    "password": "${random_password.dbpass.result}"
  }
EOF
}

## Read secret
data "aws_secretsmanager_secret" "dbsecret" {
  arn = aws_secretsmanager_secret.dbsecret.arn
}

data "aws_secretsmanager_secret_version" "rds_creds" {
  secret_id = data.aws_secretsmanager_secret.dbsecret.arn
}
