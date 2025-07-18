locals {
  project_names = [for project in split("\n", file("./project.txt")) : project if project != ""]
  input_sets = flatten([
    for project_name in local.project_names : [
      for env in local.envs : {
        name        = "${project_name}-${env}"
        org_id      = var.org_id
        project_id  = var.project_id
        env_type    = env == "prod" ? "prod" : "nonprod"
        identifier  = "${replace(project_name, "-", "")}${env}"
        connector   = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        env         = env
        pipeline_id = var.pipeline_id
        yaml        = <<-EOT
          inputSet:
            name: ${project_name}-${env}
            tags: {}
            identifier: ${replace(project_name, "-", "")}${env}
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
                          workspace: "${replace(project_name, "-", "")}${env}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
 #                             connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
                               connectorRef: testk8sconnector${env == "prod" ? "prod" : "nonprod"}
                               namespace: harness-delegate-ng
                               serviceAccountName: default
 #                             namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
 #                             serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
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
                                      minimumCount: ${env == "dev" ? 1 : 2}
                                      userGroups:
#                                        - account.acdevops
                                        - _project_all_users
                    - stage:
                        identifier: iacmapply
                        type: IACM
                        spec:
                          workspace: "${replace(project_name, "-", "")}${env}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                               connectorRef: testk8sconnector${env == "prod" ? "prod" : "nonprod"}
                               namespace: harness-delegate-ng
                               serviceAccountName: default
#                             connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
#                             namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
#                             serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
        EOT
      }
    ]
  ])

  ##### Trigge =r YAML #####
  triggers = flatten([
    for project_name in local.project_names : [
      for env in local.envs : {
        name       = "${project_name}-${env}-pipeline-trigger"
        org_id     = var.org_id
        identifier = "${replace(project_name, "-", "")}${env}pipelinetrigger"
        project_id = var.project_id
        target_id  = var.target_id
        env        = env
        yaml       = <<-EOT
          trigger:
            name: ${project_name}-${env}-pipeline-trigger
            identifier: ${replace(project_name, "-", "")}${env}pipelinetrigger
            enabled: true
            encryptedWebhookSecretIdentifier: ""
            description: ""
            tags: {}
            orgIdentifier: ${var.org_id}
            stagesToExecute: []
            projectIdentifier: ${var.project_id}
            pipelineIdentifier: ${var.pipeline_id}
            source:
              type: Webhook
              spec:
                type: Github
                spec:
                  type: PullRequest
                  spec:
                    connectorRef: ${var.repository_connector} #account.acdevopsgithubharnessconnectorssh
                    autoAbortPreviousExecutions: true
                    payloadConditions:
                      - key: changedFiles
                        operator: Regex
                        value: ${env}/.*
                      - key: targetBranch
                        operator: Equals
                        value: main
                      - key: sourceBranch
                        operator: Equals
                        value: develop
                    headerConditions: []
                    repoName: ${var.repository_name}
                    actions:
                      - Open
                      - Edit
                      - Synchronize
                      - Reopen
            inputSetRefs:
              - ${replace(project_name, "-", "")}${env}
            EOT
      }
    ]
  ])


  ##### Pipeline YAML #####
  yaml = <<-EOT
        pipeline:
          name: ${var.pipeline_name}
          identifier: ${var.pipeline_id}
          tags: {}
          template:
            templateRef: account.iacm
            versionLabel: "1"
            templateInputs:
              stages:
                - stage:
                    identifier: iacmplan
                    type: IACM
                    spec:
                      workspace: <+input>
                      infrastructure:
                        type: KubernetesDirect
                        spec:
                          connectorRef: <+input>
                          namespace: <+input>
                          serviceAccountName: <+input>
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
                                    userGroups: <+input>
                                    minimumCount: <+input>
                - stage:
                    identifier: iacmapply
                    type: IACM
                    spec:
                      workspace: <+input>
                      infrastructure:
                        type: KubernetesDirect
                        spec:
                          connectorRef: <+input>
                          namespace: <+input>
                          serviceAccountName: <+input>
          projectIdentifier: ${var.project_id}
          orgIdentifier: ${var.org_id}
      EOT
  envs = var.envs
  provider_connector = {
    nonprod = var.provider_connector_nonprod // For non-prod
    prod    = var.provider_connector_prod    // For prod

  }
  repository_connector = var.repository_connector
  project_id           = var.project_id
  repository_branch    = var.repository_branch

  workspaces = flatten([
    for project_name in local.project_names : [
      for env in local.envs : {
        identifier              = "${replace(project_name, "-", "")}${env}"
        name                    = "${project_name}-${env}"
        org_id                  = var.org_id
        project_id              = var.project_id
#        repository              = repository_name
#        repository_path         = env
        repository              = var.repository_name
        repository_path         = var.repository_path
        repository_branch       = var.repository_branch
        provisioner_type        = "opentofu"
        provisioner_version     = "1.8.1"
        cost_estimation_enabled = true
        provider_connector      = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        repository_connector    = var.repository_connector
        terraform_variables     = []
        environment_variables   = []
      }
    ]
  ])
}


module "workspaces" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-workspaces?ref=main"
  workspaces = local.workspaces
}


module "pipeline" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-pipelines?ref=main"
  name       = var.pipeline_name
  identifier = var.pipeline_id
  org_id     = var.org_id
  project_id = var.project_id
  yaml       = local.yaml
}


module "input_sets" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-inputsets?ref=main"
  input_sets = local.input_sets
  depends_on = [module.pipeline]

}


module "triggers" {
  source     = "git::https://github.com/anilnair00/ac-harness-tf-modules-develop.git//modules/harness-triggers?ref=main"
  triggers   = local.triggers
  depends_on = [module.pipeline]
}
