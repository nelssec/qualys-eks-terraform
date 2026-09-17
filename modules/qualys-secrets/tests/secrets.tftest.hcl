mock_provider "aws" {}

variables {
  customer_id   = "78c2d9a6-bb48-fc27-8001-0ab259d30ca3"
  activation_id = "4fa92c38-a2d6-4625-9ed0-b74ac72b1823"
}

run "writes_one_json_secret_with_both_keys" {
  command = apply
  assert {
    condition     = aws_secretsmanager_secret.this.name == "qualys/container-security/credentials"
    error_message = "default secret name wrong"
  }
  assert {
    condition     = jsondecode(aws_secretsmanager_secret_version.this.secret_string) == { customer_id = var.customer_id, activation_id = var.activation_id }
    error_message = "secret body must be JSON with customer_id and activation_id"
  }
  assert {
    condition     = aws_secretsmanager_secret.this.recovery_window_in_days == 7
    error_message = "default recovery window must be 7 days"
  }
  assert {
    condition     = length(aws_iam_policy.read) == 0 && output.read_policy_arn == null
    error_message = "read policy must not be created by default"
  }
}

run "creates_scoped_read_policy_when_asked" {
  command = apply
  variables {
    create_read_policy = true
    read_policy_name   = "fadv-qualys-secret-read"
  }
  override_data {
    target = data.aws_iam_policy_document.read[0]
    values = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Sid\":\"ReadQualysSensorCredentials\",\"Effect\":\"Allow\",\"Action\":[\"secretsmanager:GetSecretValue\",\"secretsmanager:DescribeSecret\"],\"Resource\":[\"arn:aws:secretsmanager:us-east-1:123456789012:secret:qualys/container-security/credentials-AbCdEf\"]}]}"
    }
  }
  assert {
    condition     = length(aws_iam_policy.read) == 1 && aws_iam_policy.read[0].name == "fadv-qualys-secret-read"
    error_message = "read policy not created"
  }
  assert {
    condition     = jsondecode(aws_iam_policy.read[0].policy).Statement[0].Action == ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret"]
    error_message = "policy must grant only GetSecretValue and DescribeSecret"
  }
}

run "rejects_non_uuid_ids" {
  command = plan
  variables {
    customer_id   = "not-a-uuid"
    activation_id = "4fa92c38-a2d6-4625-9ed0-b74ac72b1823"
  }
  expect_failures = [var.customer_id]
}
