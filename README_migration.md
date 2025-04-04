# Migrate existing Jenkins instance

When there is an existing Jenkins master instance on OpenShift 3 cluster, and you would like to use this Helm chart to
provision the new Jenkins instance on OpenShift 4 cluster, this document provides some useful instructions to help with
the process.

## Use HashiCorp Vault for credentials

Jenkins credential store is not a secure storage for secrets, so this Helm chart does not cater for it specifically.
This means secrets would need to be stored in plain text in the site configuration code, which is a really bad idea.

Before using this Helm chart, make sure that all the Jenkins credentials on the existing server are sourced from Vault.
See the following documentation on how to do that:

- [Vault Onboarding - OpenShift](https://confluence.nz.service.anz/x/EBLqE)
- [NZ Vault with Jenkins](https://confluence.nz.service.anz/x/WDOVFg)

## Export current configuration as code

1. If the existing Jenkins server doesn't yet have the
   [Configuration as Code](https://plugins.jenkins.io/configuration-as-code/) plugin, install it.
2. Login to Jenkins and export the current configuration by going to `Manage Jenkins` -> `Configuration as Code` and
   select `Download Configuration`

## Deploy and compare

Follow the main instruction to [create a new site](./README.md#creating-a-new-site), deploy it, and export the
configuration as code from the new server.

Then compare the existing and new configuration, with the help of a diff tool. Adjust the new server's configuration
until they match. Obviously there will be minor differences due being in different clusters, such as:

- Jenkins URL - `unclassified.location.url`
- Vault Kubernetes backend - `vaultKubernetesCredential.mountPath` under credentials
- Kubernetes agent image URL - recommend store and reference images in Artifactory docker registry

Note - some sections of the configuration can be ignored:

- `jenkins.authorizationStrategy` - this section is maintained by the OpenShift Login plugin
- `jenkins.labelAtoms` - this section is maintained by Jenkins itself based on the agents configured

## Migrate jobs

If adopting Job DSL, similar deploy-and-compare strategy can be used, by comparing the job's `config.xml` files.

If not adopting Job DSL, Jenkins documentation has some instruction on
[migrating jobs](https://wiki.jenkins-ci.org/display/JENKINS/Administering+Jenkins#AdministeringJenkins-Moving/copying/renamingjobs)
