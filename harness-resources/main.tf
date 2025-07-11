locals {
#  envs = var.envs
  resourcegroup_names = [for rg in split("\n", file("./rg-list.txt")) : rg if rg != ""]
  workspaces = flatten([
    for resourcegroup_name in local.resourcegroup_names : {
#      for env in local.envs : {
        identifier              = "${replace(resourcegroup_name, "-", "")}"
        name                    = "${resourcegroup_name}"
        org_id                  = var.org_id
        project_id              = var.project_id
#       repository              = repository_name
        repository              = var.repository_name
        repository_path         = var.repository_path
#        repository_path         = env
        repository_branch       = var.repository_branch
        provisioner_type        = "opentofu"
        provisioner_version     = "1.8.1"
        cost_estimation_enabled = true
        provider_connector      = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        repository_connector    = var.repository_connector
        terraform_variables     = []
        environment_variables   = []
#      }
    }
  ])
}
module "workspaces" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-workspaces?ref=main"
  workspaces = local.workspaces
}
