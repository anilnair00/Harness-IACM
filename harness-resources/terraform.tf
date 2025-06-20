terraform {
  # required_version = "1.9.4"
  backend "s3" {
    bucket   = "ac-harness-resources-terraform-state"
    encrypt  = true
    key      = "harness/ac-odh-harness-resources-tf/ac-odh-harness-resources-tf.tfstate"
    region   = "ca-central-1"
    role_arn = var.S3_BACKEND_ROLE_ARN
  }
  required_providers {
    harness = {
      source = "harness/harness"
    }
  }
}