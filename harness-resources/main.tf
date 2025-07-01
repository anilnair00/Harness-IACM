locals {
  repository_names = [for repo in split("\n", file("./repo-list.txt")) : repo if repo != ""]
  input_sets = flatten([
    for repository_name in local.repository_names : [
      for env in local.envs : {
        name        = "${repository_name}-${env}"
        org_id      = var.org_id
        project_id  = var.project_id
        env_type    = env == "prod" ? "prod" : "nonprod"
        identifier  = "${replace(repository_name, "-", "")}${env}"
        connector   = env == "prod" ? var.provider_connector_prod : var.provider_connector_nonprod
        env         = env
        pipeline_id = var.pipeline_id
        yaml        = <<-EOT
          inputSet:
            name: ${repository_name}-${env}
            tags: {}
            identifier: ${replace(repository_name, "-", "")}${env}
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
                          workspace: "${replace(repository_name, "-", "")}${env}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
                              namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
                              serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
                    - stage:
                        identifier: approval_for_cpply
                        type: Approval
                        spec:
                          execution:
                            steps:
                              - step:
                                  identifier: approval
                                  type: HarnessApproval
                                  spec:
                                    approvers:
                                      minimumCount: ${env == "int" ? 1 : 2}
                                      userGroups:
                                        - account.acdevops
                                        - _project_all_users
                    - stage:
                        identifier: iacmapply
                        type: IACM
                        spec:
                          workspace: "${replace(repository_name, "-", "")}${env}"
                          infrastructure:
                            type: KubernetesDirect
                            spec:
                              connectorRef: account.ac_eks_connector_${env == "prod" ? "prod" : "nonprod"}
                              namespace: harness-ac-${env == "prod" ? "prod" : "nonprod"}-ng
                              serviceAccountName: ac-delegate-${env == "prod" ? "prod" : "nonprod"}-sa
        EOT
      }
    ]
  ])

  ##### Trigge =r YAML #####
  triggers = flatten([
    for repository_name in local.repository_names : [
      for env in local.envs : {
        name       = "${repository_name}-${env}-pipeline-trigger"
        org_id     = var.org_id
        identifier = "${replace(repository_name, "-", "")}${env}pipelinetrigger"
        project_id = var.project_id
        target_id  = var.target_id
        env        = env
        yaml       = <<-EOT
          trigger:
            name: ${repository_name}-${env}-pipeline-trigger
            identifier: ${replace(repository_name, "-", "")}${env}pipelinetrigger
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
                    repoName: ${repository_name}
                    actions:
                      - Open
                      - Edit
                      - Synchronize
                      - Reopen
            inputSetRefs:
              - ${replace(repository_name, "-", "")}${env}
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
            templateRef: account.IACM
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
                      identifier: approval_for_cpply
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
    for repository_name in local.repository_names : [
      for env in local.envs : {
        identifier              = "${replace(repository_name, "-", "")}${env}"
        name                    = "${repository_name}-${env}"
        org_id                  = var.org_id
        project_id              = var.project_id
        repository              = repository_name
        repository_path         = env
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



