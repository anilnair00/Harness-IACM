variable "TF_VAR_HARNESS_ENDPOINT" {
  description = "The Harness API endpoint"
  type        = string
}

variable "TF_VAR_HARNESS_ACCOUNT_ID" {
  description = "The Harness account ID"
  type        = string
}

variable "TF_VAR_HARNESS_PLATFORM_API_KEY" {
  description = "The Harness platform API key"
  type        = string
}
variable "org_id" {
  description = "The Harness Organization ID"
  type        = string
}
variable "repository_name" {
  description = "The Harness Project ID"
  type        = string
}
variable "project_id" {
  description = "The Harness Project ID"
  type        = string
}
variable "pipeline_id" {
  description = "The Harness Pipeline ID"
  type        = string
}
variable "target_id" {
  description = "Target Pipeline ID"
  type        = string
}
variable "pipeline_name" {
  description = "The Harness Pipeline Name"
  type        = string
}
variable "repository_connector" {
  description = "Harness GitHub repository connector"
  type        = string
}
variable "repository_path" {
  description = "Harness GitHub repository path"
  type        = string
}
variable "repository_branch" {
  description = "GitHub repository Branch"
  type        = string
}
variable "provider_connector_nonprod" {
  description = "Harness AWS Provider NonProd Connector"
  type        = string
}
variable "provider_connector_prod" {
  description = "Harness AWS Provider PROD Connector"
  type        = string
}
variable "envs" {
  description = "AWS Environments"
  type        = list(any)
}
