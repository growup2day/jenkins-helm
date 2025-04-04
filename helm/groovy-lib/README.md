# Groovy script libraries

These are not directly referenced by the base Helm chart, but is bundled in the chart so it can be referenced in the
values files as a mechanism to share common groovy code.

To reference these scripts, use Helm's `.Files.Get` function, make sure that it's indented correctly.

Example for using a standalone script:

```yaml
JCasC:
  configScripts:
    jobs-setup: |
      jobs:
        - script: |
            {{- .Files.Get "groovy-lib/ib/clean-vm-slaves-job.groovy" | nindent 6 }}
```

Example for using a helper script that defines functions to be called:

```yaml
JCasC:
  configScripts:
    jobs-setup: |
      jobs:
        - script: |
            {{- .Files.Get "groovy-lib/multibranch-pipeline-helper.groovy" | nindent 6 }}
            bitbucketMultibranchPipelineJob(
              jobName: "Preauth-Pipeline-ManagedServers",
              project: "DIG",
              repo: "preauth",
              credentialsId: "Bitbucket_ServiceAccount",
              scriptPath: "Jenkinsfile-ManagedServers",
              branchRegex: "ocp4-test",
              shallowCloneDepth: 1000,
            )
```

See comments in each helper script on how to consume it.
