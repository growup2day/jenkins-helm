// Provides a helper function to setup a BitBucket Team/Project job
// See defaultOptions object for mandatory and optional parameters
//
// Usage in JCasC
//
// JCasC:
//   configScripts:
//     jobs-setup: |
//       jobs:
//         - script: |
//             {{- .Files.Get "groovy-lib/organization-folder-helper.groovy" | nindent 6 }}
//             bitbucketOrganizationFolder(
//               folderName: "digital",
//               project: "DIG",
//               credentialsId: "bitbucket",
//               branchRegex: "PR-.*",
//             )
def bitbucketOrganizationFolder(
  Map options
  ) {
  def defaultOptions = [
    // mandatory parameters

    folderName: '',
    project: '',
    credentialsId: '',
    // default to an non-existent branch so personal instances would not take over all branches by mistake
    branchRegex: 'non-existent',

    // optional parameters below

    repoRegex: null,
    displayName: null,
    serverUrl: 'https://bitbucket.nz.service.anz',
    scriptPath: 'Jenkinsfile',

    // 1 = Exclude branches that are also filed as PRs
    // 2 = Only branches that are also filed as PRs
    // 3 = All branches
    branchDiscoveryStrategyId: 3,

    // set to false to only build branches
    discoverPullRequests: true,
    // 1 = Merging the pull request with the current target branch revision
    // 2 = The current pull request revision
    // 3 = Both the current pull request revision and the pull request merged with the current target branch revision
    pullRequestDiscoveryStrategyId: 2,
    
    // set to false disable PR from fork
    discoverForkPullRequests: true,
    // 1 = Merging the pull request with the current target branch revision
    // 2 = The current pull request revision
    // 3 = Both the current pull request revision and the pull request merged with the current target branch revision
    forkPullRequestDiscoveryStrategyId: 2,

    // set to false to not exclude pull requests from public repositories
    excludePublicRepoPullRequest: true,

    // set to false to not disable webhook management
    disableHookManagement: true,

    // Scan SCM periodically if not otherwise run
    // set to null to skip periodic scan
    periodicScanInterval: '15m',

    // set any of the following 2 options to a positive value to disgard old items (i.e. deleted branches, merged PRs)
    discardOldItemsDays: 1,
    discardOldItemsNum: 1,

    // The regex pattern for the Automatic branch project triggering > Branch names to build automatically configuration
    // This controls which branches will build automatically from SCM triggering
    branchNamesToBuildAutomaticallyRegex: null
  ]
  options = defaultOptions << options

  // API documentation for organizationFolder is available at <your-jenkins>/plugin/job-dsl/api-viewer/index.html
  organizationFolder(options.folderName) {
    if (options.displayName) {
      displayName(options.displayName)
    }

    organizations {
      bitbucket {
        serverUrl(options.serverUrl)
        credentialsId(options.credentialsId)
        repoOwner(options.project)
        traits {
          if (options.repoRegex) {
            sourceRegexFilter {
              regex(options.repoRegex)
            }
          }
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
          pruneStaleBranchTrait()
          if (options.excludePublicRepoPullRequest) {
            bitbucketPublicRepoPullRequestFilter() 
          }
          if (options.disableHookManagement) {
            bitbucketWebhookRegistration {
              mode("DISABLE")
            }
          }
        }
      }
    }
    projectFactories {
      workflowMultiBranchProjectFactory {
        scriptPath(options.scriptPath)
      }
    }
    if (options.branchNamesToBuildAutomaticallyRegex != null) {
      properties {
        noTriggerOrganizationFolderProperty {
          branches(options.branchNamesToBuildAutomaticallyRegex)
        }
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
          daysToKeep(options.discardOldItemsDays)
          numToKeep(options.discardOldItemsNum)
        }
      }
    }
    if (options.discoverForkPullRequests) {
      configure { node ->
        // There's currently no nice way to configure fork PR discovery
        // see https://github.com/jenkinsci/bitbucket-branch-source-plugin/issues/290
        // and https://issues.jenkins.io/browse/JENKINS-61119
        def traits = node / navigators / 'com.cloudbees.jenkins.plugins.bitbucket.BitbucketSCMNavigator' / traits
        traits << 'com.cloudbees.jenkins.plugins.bitbucket.ForkPullRequestDiscoveryTrait' {
            strategyId(options.forkPullRequestDiscoveryStrategyId)
            trust(class: 'com.cloudbees.jenkins.plugins.bitbucket.ForkPullRequestDiscoveryTrait$TrustEveryone') 
        }
      }
    }
  }
}
