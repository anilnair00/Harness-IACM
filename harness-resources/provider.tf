provider "harness" {
  endpoint         = var.TF_VAR_HARNESS_ENDPOINT
  account_id       = var.TF_VAR_HARNESS_ACCOUNT_ID
  platform_api_key = var.TF_VAR_HARNESS_PLATFORM_API_KEY
}