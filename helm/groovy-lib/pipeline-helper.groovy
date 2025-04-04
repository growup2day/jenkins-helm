// Provides a helper function to setup a pipeline job
// See defaultOptions object for mandatory and optional parameters
//
// Usage in JCasC
//
// JCasC:
//   configScripts:
//     jobs-setup: |
//       jobs:
//         - script: |
//             {{- .Files.Get "groovy-lib/pipeline-helper.groovy" | nindent 6 }}
//             bitbucketPipelineJob(
//               jobName: "ib-frontend-mocks",
//               gitUrl: "https://bitbucket.nz.service.anz/scm/ib/internetbanking.git",
//               credentialsId: "bitbucket",
//               branch: "master",
//             )
def bitbucketPipelineJob(
  Map options
  ) {
  def defaultOptions = [
    // mandatory parameters

    jobName: '',
    gitUrl: '',
    credentialsId: '',
    // default to an non-existent branch so personally instances would not take over all branches
    branch: 'non-existent',

    // optional parameters below
    disableConcurBuilds: true,
    displayName: null,
    description: null,
    scriptPath: 'Jenkinsfile',
    lightweight: true,
    
    // set to true when using the Jira plugin
    jiraProject: false,
    jiraSite: '',

    // set to positive number to enable shallow clone (only works for branch builds)
    shallowCloneDepth: 0,

    // trigger build when change is pushed to source control, set to false if not desired
    triggerBuildOnPush: true,

    // cron spec defining the frequency Jenkins should trigger the job
    cronSpec: null,

    // trigger builds using a webhook (from BitBucket), default to false
    // example usage in JCasC
    //    webhookTrigger: true
    //    triggerGenericVariables: [[key: 'requestBody', value: '$', expressionType: 'JSONPath'][key: '', value: '', expressionType: 'XPath']]
    //    triggerCredentialToken: 'token'
    //    triggerCause: 'Triggered by BitBucket webhook'
    //    triggerPrintPost: true
    // expressionType can only be JSONPath or XPath
    webhookTrigger: false,
    triggerGenericVariables: [],
    triggerCredentialToken: '',
    triggerCause: '',
    triggerPrintPost: false,

    // cron spec defining the frequency Jenkins should poll the source repo for changes
    pollSCMSpec: 'H * * * *',

    // set any of the following 2 options to a string containing positive integer disgard old builds
    buildRetentionDaysStr: "-1",
    buildRetentionNumStr: "-1",

    // set parameters for parameterized builds
    // example usage in JCasC
    //   parametersNeeded: true
    //   stringParams: [[name: 'BRANCH', desc: 'Branch name?', trim: false]]
    //   choiceParams: [[name: 'ENV_CHOICE', desc: 'Environment?', options: ['sit', 'oat']]]
    parametersNeeded: false,
    stringParams: [],
    choiceParams: [],
    booleanParams: [],

    // Trigger builds remotely
    // example usage in JCasC
    // authenticationToken: 'secret'
    authenticationToken: null,

    // Authorization setting for individual jobs using the Matrix Authorization Strategy Plugin
    // example usage in JCaC
    //      authorization: true
    //      jobPerms: [[name:, 'anonymous', type: 'user', permissions: ['Job/Read']],[name: 'authenticated', type: 'group', permissions: ['Job/Read','Job/Build']]]
    authorization: false,
    blocksInheritance: true,
    jobPerms: [],
  ]
  options = defaultOptions << options

  pipelineJob(options.jobName) {
    if (options.displayName) {
      displayName(options.displayName)
    }
    if (options.description) {
      description(options.description)
    }

    definition {
      cpsScm {
        scm {
          git {
            remote {
              url(options.gitUrl)
              credentials(options.credentialsId)
            }
            branch(options.branch)
            if (options.shallowCloneDepth > 0) {
              extensions {
                cloneOptions {
                  noTags(true)
                  honorRefspec(false)
                  reference("")
                  timeout(10)
                  shallow(true)
                  depth(options.shallowCloneDepth)
                }
              }
            }
          }
        }
        lightweight(options.lightweight)
        scriptPath(options.scriptPath)
      }
    }
    properties {
      if(options.disableConcurBuilds) {
        disableConcurrentBuilds()
      }
      
      if(options.jiraProject) {
        jiraProjectProperty {
          siteName(options.jiraSite)
        }
      }
      
      pipelineTriggers {
        triggers {
          if (options.triggerBuildOnPush) {
            bitbucketPush()
          }
          if (options.pollSCMSpec) {
            pollSCM {
              scmpoll_spec(options.pollSCMSpec)
            }
          }
          if (options.cronSpec) {
            cron {
              spec(options.cronSpec)
            }
          }
          if (options.webhookTrigger) {
            GenericTrigger {
              genericVariables {
                for (variable in options.triggerGenericVariables) {
                  genericVariable {
                    key(variable.key)
                    value(variable.value)
                    expressionType(variable.expressionType)
                  }
                }
              }
              token(options.triggerToken)
              tokenCredentialId(options.triggerCredentialToken)
              causeString(options.triggerCause)
              printPostContent(options.triggerPrintPost)
            }
          }
        }
      }

      if (options.authorization) {
        authorizationMatrix {
          inheritanceStrategy {
            if (options.blocksInheritance) {
              nonInheriting()
            } else {
              inheriting()
            }
          }
          entries {
            for (indv in options.jobPerms) {
              if (indv.type == 'user') {
                user {
                  name(indv.name)
                  permissions(indv.permissions)
                }
              } else if (indv.type == 'group') {
                group {
                  name(indv.name)
                  permissions(indv.permissions)
                }
              }
            }
          }
        }
      }

      if (options.buildRetentionDaysStr != "-1" || options.buildRetentionNumStr != "-1") {
        buildDiscarder {
          strategy {
            logRotator {
              daysToKeepStr(options.buildRetentionDaysStr)
              numToKeepStr(options.buildRetentionNumStr)
              artifactDaysToKeepStr("")
              artifactNumToKeepStr("")
            }
          }
        }
      }

      if (options.parametersNeeded) {
        parameters {
          parameterDefinitions {
            for (param in options.stringParams) {
              def paramName = param['name']
              def paramDesc = param['desc']
              def paramDefaultValue = param['defaultValue']
              def paramTrim = param['trim']
              if (paramName || paramDesc) {
                stringParam {
                  name(paramName)
                  description(paramDesc)
                  defaultValue(paramDefaultValue ?: '')
                  trim(paramTrim ?: false)
                }
              }
            }
            for (param in options.booleanParams) {
              def paramName = param['name']
              def paramDesc = param['desc']
              def paramDefaultValue = param['defaultValue']
              if (paramName || paramDesc) {
                booleanParam {
                  name(paramName)
                  description(paramDesc)
                  defaultValue(paramDefaultValue ?: false)
                }
              }
            }
            for (param in options.passwordParams) {
              def paramName = param['name']
              def paramDesc = param['desc']
              def paramDefaultValue = param['defaultValue']
              if (paramName || paramDesc) {
                password {
                  name(paramName)
                  description(paramDesc)
                  defaultValueAsSecret(paramDefaultValue)
                }
              }
            }
            for (param in options.choiceParams) {
              def paramName = param['name']
              def paramDesc = param['desc']
              def choiceOptions = param['options']
              if (paramName || paramDesc || choiceOptions) {
                choiceParam {
                  name(paramName)
                  description(paramDesc)
                  choices(choiceOptions ?: [])
                }
              }
            }
          }
        }
      }
      if (options.authenticationToken) {
        authenticationToken(options.authenticationToken)
      }
    }
  }
}