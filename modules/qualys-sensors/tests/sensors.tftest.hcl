mock_provider "aws" {}
mock_provider "helm" {}

variables {
  cluster_arn            = "arn:aws:eks:us-east-1:123456789012:cluster/demo"
  qualys_platform        = "US2"
  credentials_secret_arn = "arn:aws:secretsmanager:us-east-1:123456789012:secret:qualys/container-security/credentials-AbCdEf"
}

run "reads_secret_and_passes_ids_via_set_sensitive" {
  command = plan

  override_data {
    target = data.aws_secretsmanager_secret_version.credentials
    values = {
      secret_string = "{\"customer_id\":\"78c2d9a6-bb48-fc27-8001-0ab259d30ca3\",\"activation_id\":\"4fa92c38-a2d6-4625-9ed0-b74ac72b1823\"}"
    }
  }

  assert {
    condition     = helm_release.this.chart == "qualys-tc" && helm_release.this.version == "2.10.0" && helm_release.this.repository == "https://qualys.github.io/Qualys-Helm-Charts/"
    error_message = "chart coordinates wrong"
  }
  assert {
    condition     = helm_release.this.namespace == "qualys" && helm_release.this.create_namespace && helm_release.this.atomic && helm_release.this.cleanup_on_fail && helm_release.this.wait && helm_release.this.timeout == 600
    error_message = "release safety settings wrong"
  }
  assert {
    condition     = anytrue([for s in helm_release.this.set_sensitive : s.name == "global.customerId" && s.value == "78c2d9a6-bb48-fc27-8001-0ab259d30ca3"])
    error_message = "customerId must be passed via set_sensitive"
  }
  assert {
    condition     = anytrue([for s in helm_release.this.set_sensitive : s.name == "global.activationId" && s.value == "4fa92c38-a2d6-4625-9ed0-b74ac72b1823"])
    error_message = "activationId must be passed via set_sensitive"
  }
  assert {
    condition     = length(helm_release.this.values) == 2 && !can(regex("78c2d9a6|4fa92c38", join("\n", helm_release.this.values)))
    error_message = "values must be [rendered, extra] and must not contain credentials"
  }
  assert {
    condition     = yamldecode(helm_release.this.values[0]).global.gatewayUrl == "https://gateway.qg2.apps.qualys.com"
    error_message = "rendered values not wired from qualys-sensor-values"
  }
}

run "custom_secret_keys_and_pull_secret_password" {
  command = plan
  variables {
    credentials_secret_keys = { customer_id = "CustomerId", activation_id = "ActivationId" }
    image_pull_secrets = [
      { name = "artifactory", create = true, registry_url = "registry.corp.example.com", username = "svc", password = "s3cr3t" },
    ]
  }
  override_data {
    target = data.aws_secretsmanager_secret_version.credentials
    values = {
      secret_string = "{\"CustomerId\":\"78c2d9a6-bb48-fc27-8001-0ab259d30ca3\",\"ActivationId\":\"4fa92c38-a2d6-4625-9ed0-b74ac72b1823\"}"
    }
  }
  assert {
    condition     = anytrue([for s in helm_release.this.set_sensitive : s.name == "global.customerId" && s.value == "78c2d9a6-bb48-fc27-8001-0ab259d30ca3"])
    error_message = "custom secret key names not honoured"
  }
  assert {
    condition     = anytrue([for s in helm_release.this.set_sensitive : s.name == "global.imagePullSecrets[0].password" && s.value == "s3cr3t"])
    error_message = "pull secret password must be in set_sensitive"
  }
}

run "fails_clearly_when_secret_lacks_keys" {
  command = plan
  override_data {
    target = data.aws_secretsmanager_secret_version.credentials
    values = {
      secret_string = "{\"username\":\"x\"}"
    }
  }
  expect_failures = [data.aws_secretsmanager_secret_version.credentials]
}

run "fails_clearly_when_secret_is_not_json" {
  command = plan
  override_data {
    target = data.aws_secretsmanager_secret_version.credentials
    values = {
      secret_string = "plain-text"
    }
  }
  expect_failures = [data.aws_secretsmanager_secret_version.credentials]
}
