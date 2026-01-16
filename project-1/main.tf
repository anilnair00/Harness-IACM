locals {
  identifier = "${replace(var.project_name, "-", "")}${var.envs}"
  env_type   = var.envs

  ##### INPUT SET #####
  input_sets = {
    name        = "${var.project_name}-${var.envs}"
    org_id      = var.org_id
    project_id  = var.project_id
    identifier  = local.identifier
    env         = var.envs
    pipeline_id = var.pipeline_id
    yaml = <<-EOT
      inputSet:
        name: ${var.project_name}-${var.envs}
        identifier: ${local.identifier}
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
                      workspace: "${local.identifier}"
                      infrastructure:
                        type: KubernetesDirect
                        spec:
                          connectorRef: testk8sconnector${local.env_type}
                          namespace: harness-delegate-ng
                          serviceAccountName: default
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
                                  minimumCount: ${var.envs == "non-prod" ? 1 : 2}
                                  userGroups:
                                    - _project_all_users
                - stage:
                    identifier: iacmapply
                    type: IACM
                    spec:
                      workspace: "${local.identifier}"
                      infrastructure:
                        type: KubernetesDirect
                        spec:
                          connectorRef: testk8sconnector${local.env_type}
                          namespace: harness-delegate-ng
                          serviceAccountName: default
    EOT
  }

  ##### TRIGGER #####
  triggers = {
    name       = "${var.project_name}-${var.envs}-pipeline-trigger"
    identifier = "${local.identifier}pipelinetrigger"
    org_id     = var.org_id
    project_id = var.project_id
    target_id  = var.target_id
    yaml = <<-EOT
      trigger:
        name: ${var.project_name}-${var.envs}-pipeline-trigger
        identifier: ${local.identifier}pipelinetrigger
        enabled: true
        orgIdentifier: ${var.org_id}
        projectIdentifier: ${var.project_id}
        pipelineIdentifier: ${var.pipeline_id}
        source:
          type: Webhook
          spec:
            type: Github
            spec:
              type: PullRequest
              spec:
                connectorRef: ${var.repository_connector}
                payloadConditions:
                  - key: changedFiles
                    operator: Regex
                    value: ${var.envs}/.*
                  - key: targetBranch
                    operator: Equals
                    value: main
                  - key: sourceBranch
                    operator: Equals
                    value: develop
                repoName: ${var.repository_name}
                actions:
                  - Open
                  - Edit
                  - Synchronize
                  - Reopen
        inputSetRefs:
          - ${local.identifier}
    EOT
  }

  ##### PIPELINE #####
  pipeline_yaml = <<-EOT
    pipeline:
      name: ${var.pipeline_name}
      identifier: ${var.pipeline_id}
      template:
        templateRef: account.iacm
        versionLabel: "1"
      projectIdentifier: ${var.project_id}
      orgIdentifier: ${var.org_id}
  EOT

  ##### WORKSPACE #####
  workspaces = {
    identifier              = local.identifier
    name                    = "${var.project_name}-${var.envs}"
    org_id                  = var.org_id
    project_id              = var.project_id
    repository              = var.repository_name
    repository_path         = var.repository_path
    repository_branch       = var.envs
    provisioner_type        = "opentofu"
    provisioner_version     = "1.8.1"
    cost_estimation_enabled = true
    provider_connector      = var.envs == "nonpod" ? var.provider_connector_prod : var.provider_connector_nonprod
    repository_connector    = var.repository_connector
#    terraform_variables     = []
#    environment_variables   = []
     variable_files          = []
  }
}
module "workspaces" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-workspaces?ref=feature"
  workspaces = local.workspaces
}

