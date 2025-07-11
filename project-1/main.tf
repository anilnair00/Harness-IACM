locals {
#  envs = var.envs
  resourcegroup_names = [for rg in split("\n", file("./rg-list.txt")) : rg if rg != ""]
  input_sets = flatten([
    for resourcegroup_name in local.resourcegroup_names : {
 #     for env in local.envs : {
        name        = "${resourcgroup_name}"
        org_id      = var.org_id
        project_id  = var.project_id
        env_type    = env == "prod" ? "prod" : "nonprod"
        identifier  = "${replace(resourcegroup_name, "-", "")}"
#        connector   = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        connector   = can(regex("(?i)prod", resourcegroup_name)) ? var.provider_connector_prod : var.provider_connector_nonprod
        env         = env
        pipeline_id = var.pipeline_id
        yaml        = <<-EOT
          inputSet:
            name: ${resourcegroup_name}
            tags: {}
            identifier: ${replace(resourcegroup_name, "-", "")}
            orgIdentifier: ${var.org_id}
            projectIdentifier: ${var.project_id}
            pipeline:
              identifier: ${var.pipeline_id}
              template:
                templateInputs:
                  stages:
                    - stage:
                        identifier: iacmplan
                        type: IACM
                        spec:
                          workspace: "${replace(resourcegroup_name, "-", "")}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
 #                             connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
                              connectorRef: can(regex("(?i)prod", resourcegroup_name)) ? var.kubernetes_connector_prod : var.kubernetes_connector_nonprod
                              namespace: harness-delegate-ng
                              serviceAccountName: default
#                              namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
#                              serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
                    - stage:
                        identifier: approval_for_apply
                        type: Approval
                        spec:
                          execution:
                            steps:
                              - step:
                                  identifier: approval
                                  type: HarnessApproval
                                  spec:
                                    approvers:
                                      minimumCount: 1
                                      userGroups:
#                                        - account.acdevops
                                        - _project_all_users
                    - stage:
                        identifier: iacmapply
                        type: IACM
                        spec:
                          workspace: "${replace(resourcegroup_name, "-", "")}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
#                              connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
#                              namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
#                              serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
                              connectorRef: can(regex("(?i)prod", resourcegroup_name)) ? var.kubernetes_connector_prod : var.kubernetes_connector_nonprod
                              namespace: harness-delegate-ng
                              serviceAccountName: default
        EOT
    }
  ])

  workspaces = flatten([
    for resourcegroup_name in local.resourcegroup_names : {
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
#        provider_connector      = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        provider_connector      = can(regex("(?i)prod", resourcegroup_name)) ? var.provider_connector_prod : var.provider_connector_nonprod
        repository_connector    = var.repository_connector
        terraform_variables     = []
        environment_variables   = []
      }
  ])
}
module "workspaces" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-workspaces?ref=main"
  workspaces = local.workspaces
}
module "input_sets" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-inputsets?ref=main"
  input_sets = local.input_sets
#  depends_on = [module.pipeline]

}

