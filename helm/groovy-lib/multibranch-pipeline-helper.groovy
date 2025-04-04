// Provides a helper function to create a BitBucket multi-branch pipeline job.
// See defaultOptions object for mandatory and optional parameters
//
// Usage in JCasC
//
// JCasC:
//   configScripts:
//     jobs-setup: |
//       jobs:
//         - script: |
//             {{- .Files.Get "groovy-lib/multibranch-pipeline-helper.groovy" | nindent 6 }}
//             bitbucketMultibranchPipelineJob(
//               jobName: "preauth",
//               project: "DIG",
//               repo: "preauth",
//               credentialsId: "bitbucket",
//               branchRegex: "PR-.*",
//             )
def bitbucketMultibranchPipelineJob(
  Map options
  ) {
  def defaultOptions = [
    // mandatory parameters

    jobName: '',
    project: '',
    repo: '',
    credentialsId: '',
    // default to an non-existent branch so personal instances would not take over all branches by mistake
    branchRegex: 'non-existent',

    // optional parameters below

    displayName: null,
    serverUrl: 'https://bitbucket.nz.service.anz',
    scriptPath: 'Jenkinsfile',

    // 1 = Exclude branches that are also filed as PRs
    // 2 = Only branches that are also filed as PRs
    // 3 = All branches
    branchDiscoveryStrategyId: 1,

    // set to false to only build branches
    discoverPullRequests: true,
    // 1 = Merging the pull request with the current target branch revision
    // 2 = The current pull request revision
    // 3 = Both the current pull request revision and the pull request merged with the current target branch revision
    pullRequestDiscoveryStrategyId: 1,

    // set to positive number to enable shallow clone (only works for branch builds)
    shallowCloneDepth: 0,
    // Specify a folder containing a repository that will be used by Git as a reference during clone operations.
    // This option will be ignored if the folder is not available on the controller or agent where the clone is being executed.
    cloneReference: "",

    // A ref spec to fetch. Any occurrences of @{remote} will be replaced by the remote name (which defaults to origin) before use.
    refSpecs: null,

    // set any of the following 2 options to a string containing positive integer disgard old builds
    buildRetentionDaysStr: "-1",
    buildRetentionNumStr: "-1",

    // Scan SCM periodically if not otherwise run
    // set to null to skip periodic scan
    periodicScanInterval: '15m',

    // set any of the following 2 options to a positive value to disgard old items (i.e. deleted branches, merged PRs)
    discardOldItemsDays: 1,
    discardOldItemsNum: 3,

    // set to true to suppress automatic SCM triggering
    noTriggerBranchProperty: false,
    // NONE     = suppress all triggers
    // INDEXING = suppress indexing only
    // EVENTS   = suppress events (webhooks) only
    noTriggerBranchPropertyStrategy: 'NONE',
    // regular expression of branch names which will be triggered automatically if noTriggerBranchProperty is set to true.
    // All branches which names don't match the regular expression could be only scheduled manually or via CLI/REST.
    noTriggerBranchPropertyTriggeredBranchesRegex: '^$'
  ]
  options = defaultOptions << options

  multibranchPipelineJob(options.jobName) {
    if (options.displayName) {
      displayName(options.displayName)
    }

    branchSources {
      branchSource {
        source {
          bitbucket {
            serverUrl(options.serverUrl)
            credentialsId(options.credentialsId)
            repoOwner(options.project)
            repository(options.repo)
            traits {
              bitbucketBranchDiscovery {
                strategyId(options.branchDiscoveryStrategyId)
              }
              if (options.discoverPullRequests) {
                bitbucketPullRequestDiscovery {
                  strategyId(options.pullRequestDiscoveryStrategyId)
                }
              }
              headRegexFilter {
                regex(options.branchRegex)
              }
              if (options.shallowCloneDepth > 0 || options.cloneReference) {
                cloneOptionTrait {
                  extension {
                    noTags(true)
                    honorRefspec(false)
                    reference(options.cloneReference)
                    timeout(10)
                    if (options.shallowCloneDepth > 0) {
                      shallow(true)
                      depth(options.shallowCloneDepth)
                    } else {
                      shallow(false)
                    }
                  }
                }
              }
              pruneStaleBranchTrait()
              if (options.refSpecs) {
                refSpecsSCMSourceTrait {
                  templates {
                    refSpecTemplate {
                      value(options.refSpecs)
                    }
                  }
                }
              }
            }
          }
        }
        strategy {
          defaultBranchPropertyStrategy {
            props {
              if (options.buildRetentionDaysStr != "-1" || options.buildRetentionNumStr != "-1") {
                buildRetentionBranchProperty {
                  buildDiscarder {
                    logRotator {
                      daysToKeepStr(options.buildRetentionDaysStr)
                      numToKeepStr(options.buildRetentionNumStr)
                      artifactDaysToKeepStr("")
                      artifactNumToKeepStr("")
                    }
                  }
                }
              }
              if (options.noTriggerBranchProperty) {
                noTriggerBranchProperty {
                  strategy(options.noTriggerBranchPropertyStrategy)
                  triggeredBranchesRegex(options.noTriggerBranchPropertyTriggeredBranchesRegex)
                }
              }
            }
          }
        }
      }
    }
    factory {
      workflowBranchProjectFactory {
        scriptPath(options.scriptPath)
      }
    }
    triggers {
      if (options.periodicScanInterval) {
        periodicFolderTrigger {
          interval(options.periodicScanInterval)
        }
      }
    }
    if (options.discardOldItemsDays > 0 || options.discardOldItemsNum > 0) {
      orphanedItemStrategy {
        discardOldItems {
          if (options.discardOldItemsDays > 0) {
            daysToKeep(options.discardOldItemsDays)
          }
          if (options.discardOldItemsNum > 0) {
            numToKeep(options.discardOldItemsNum)
          }
        }
      }
    }
  }
}