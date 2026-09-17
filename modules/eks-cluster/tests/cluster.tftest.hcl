mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = {
      account_id = "123456789012"
      arn        = "arn:aws:iam::123456789012:user/test"
      user_id    = "AIDACKCEVSQ6C2EXAMPLE"
    }
  }

  mock_data "aws_iam_policy_document" {
    defaults = {
      json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}"
    }
  }

  mock_data "aws_partition" {
    defaults = {
      partition          = "aws"
      dns_suffix         = "amazonaws.com"
      reverse_dns_prefix = "com.amazonaws"
    }
  }

  mock_data "aws_iam_session_context" {
    defaults = {
      arn        = "arn:aws:iam::123456789012:user/test"
      issuer_arn = "arn:aws:iam::123456789012:user/test"
    }
  }
}
mock_provider "tls" {}
mock_provider "time" {}

variables {
  name       = "qualys-demo"
  vpc_id     = "vpc-0123456789abcdef0"
  subnet_ids = ["subnet-0a", "subnet-0b", "subnet-0c"]
}

run "rejects_fargate_profile_that_selects_sensor_namespace" {
  command = plan
  variables {
    fargate_profiles = {
      apps = { selectors = [{ namespace = "apps" }, { namespace = "qualys" }] }
    }
  }
  expect_failures = [var.fargate_profiles]
}

run "rejects_public_access_without_cidrs" {
  command = plan
  variables {
    endpoint_public_access = true
  }
  expect_failures = [var.endpoint_public_access_cidrs]
}

run "rejects_unknown_log_type" {
  command = plan
  variables {
    enabled_log_types = ["api", "everything"]
  }
  expect_failures = [var.enabled_log_types]
}

run "accepts_fargate_profile_on_other_namespaces_and_plans" {
  command = plan
  variables {
    enable_irsa = false
    fargate_profiles = {
      apps = { selectors = [{ namespace = "apps", labels = { tier = "web" } }] }
    }
    endpoint_public_access       = true
    endpoint_public_access_cidrs = ["203.0.113.0/24"]
  }
  assert {
    condition     = module.eks.fargate_profiles != null
    error_message = "community module should be invoked with the fargate profile"
  }
}
