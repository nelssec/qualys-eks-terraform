resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  description             = "Qualys Container Security enrollment credentials (customer_id, activation_id)"
  kms_key_id              = var.kms_key_id
  recovery_window_in_days = var.recovery_window_in_days
  tags                    = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id = aws_secretsmanager_secret.this.id
  secret_string = jsonencode({
    customer_id   = var.customer_id
    activation_id = var.activation_id
  })
}

data "aws_iam_policy_document" "read" {
  count = var.create_read_policy ? 1 : 0

  statement {
    sid       = "ReadQualysSensorCredentials"
    effect    = "Allow"
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [aws_secretsmanager_secret.this.arn]
  }
}

resource "aws_iam_policy" "read" {
  count = var.create_read_policy ? 1 : 0

  name        = var.read_policy_name
  description = "Read the Qualys Container Security credentials secret"
  policy      = data.aws_iam_policy_document.read[0].json
  tags        = var.tags
}
