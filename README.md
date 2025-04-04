# Jenkins Helm Chart

Reusable Jenkins setup using Helm and Jenkins Configuration as Code plugin (JCasC), inspired by the open source
[Jenkins helm-charts](https://github.com/jenkinsci/helm-charts).

It is designed to support:

- Different sites (IB, CSP, etc.)
- Different variants (dev/personal, nonprod, prod)
- Different clusters (OCP3, OCP4-cs1, OCP4-cs2)

**Table of Contents**

- [Overview](#overview)
- [Usage guide](#usage-guide)
  - [Prerequisites](#prerequisites)
  - [Creating a new site](#creating-a-new-site)
  - [Determine access permissions](#determine-access-permissions)
    - [Anonymous access](#anonymous-access)
  - [Configuration as code](#configuration-as-code)
    - [Config scripts](#config-scripts)
    - [Referencing Helm values and variables](#referencing-helm-values-and-variables)
    - [Default configs](#default-configs)
    - [Using default configs together with custom config scripts](#using-default-configs-together-with-custom-config-scripts)
  - [Seed jobs with Job DSL](#seed-jobs-with-job-dsl)
  - [Executing groovy scripts](#executing-groovy-scripts)
  - [Enable render of build artifacts](#enable-render-of-build-artifacts)
  - [Deploying](#deploying)
  - [Deleting Jenkins instance](#deleting-jenkins-instance)
- [Jenkins openshift-pipeline library](#jenkins-openshift-pipeline-library)
  - [Service account self-provisioner](#service-account-self-provisioner)
  - [OpenShift cluster name](#openshift-cluster-name)

<a name="overview"></a>

## Overview

![Building and deploying Jenkins](https://confluence.nz.service.anz/rest/gliffy/1.0/embeddedDiagrams/24fefa88-ff36-4676-b3bd-b3fbc2e173a6.png)

<a name="usage-guide"></a>

## Usage guide

<a name="prerequisites"></a>

### Prerequisites

1. A Linux environment (as the helper scripts requires Bash)
2. Command line tools (all can be provisioned with
   [ANZ Developer Setup ansible scripts](https://bitbucket.nz.service.anz/projects/DS/repos/ansible/browse))
   - [git](https://git-scm.com/)
   - [OpenShift Client v4](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html)
   - [helm](https://helm.sh/docs/intro/install/)
   - [skopeo](https://github.com/containers/skopeo)
   - **If on a JAMF Macbook**: [coreutils](https://github.com/coreutils/coreutils). This will provide `sha256sum`
3. Clone this repo
4. Access (with at least the `edit` role) to the target OpenShift cluster namespaces that the Jenkins master needs to
   deploy to. To login to the OpenShift cluster, either
   - first login from the web console, then select the `Copy Login Command` option from the user dropdown (top right
     corner of the page), or
   - use the CLI Token Request link below directly

URLs for OpenShift clusters

| Cluster   | Web Console                                                     | CLI Token Request                                                        |
| --------- | --------------------------------------------------------------- | ------------------------------------------------------------------------ |
| cs1-dev   | https://console-openshift-console.apps.cs1-dev.nz.service.test/ | https://oauth-openshift.apps.cs1-dev.nz.service.test/oauth/token/request |
| cs2-dev   | https://console-openshift-console.apps.cs2-dev.nz.service.test/ | https://oauth-openshift.apps.cs2-dev.nz.service.test/oauth/token/request |
| cs1-prod  | https://console-openshift-console.apps.cs1.nz.service.anz/      | https://oauth-openshift.apps.cs1.nz.service.anz/oauth/token/request      |
| cs2-prod  | https://console-openshift-console.apps.cs2.nz.service.anz/      | https://oauth-openshift.apps.cs2.nz.service.anz/oauth/token/request      |
| ocp3-dev  | https://caas-master.nz.service.test:8443/                       | https://caas-master.nz.service.test:8443/oauth/token/request             |
| ocp3-prod | https://caas-master.nzlb.service.anz:8443/                      | https://caas-master.nzlb.service.anz:8443/oauth/token/request            |

<a name="creating-a-new-site"></a>

### Creating a new site

If you are migrating an existing Jenkins instance (e.g. from OpenShift 3 cluster), see also the
[Migration guide](./README_migration.md) for some extra tips.

A site defines a group of one or more Jenkins instance (variants) with similar setups.

1. Create a new site folder under `./sites` for your team, e.g. `./sites/ib`.
2. Decide on the number of variants required, usually you need at least 2

   - `nonprod` - for an instance deployed in the nonprod cluster to run builds for pull requests
   - `prod` - for an instance deployed in the prod cluster to run builds for the master branch

   The reason for the separate prod/nonprod instance is better security:

   - Separate namespace in NZ Vault, so that the secrets required for production deployments are exposed to smaller set
     of users
   - Separate access control for the Jenkins master instance

   Note - there is no limitation on the number of variants, or their names.

3. Define the extra plugins and their versions required for your site in a `plugins.txt` file. The filename is
   important, so if different variants requires different plugins, then they need to be placed in separate sub-folders
   in the site folder.
4. Define the value files required to setup each variant. Use file `helm/values.yaml` as reference - you only need to
   define values that differs from the default. Apply the DRY (don't repeat yourself) principle where it make sense and
   extract common values to value file shared by multiple variants. Some common value files of each cluster is provided
   directory `./sites/shared`

   To configure the Jenkins instance "as-code", use the `JCasC` block in the values file (see
   [Configuration as code](#configuration-as-code) section below)

5. Add a `config.sh` script in the site folder (see `sites/sample/config.sh` for an example), and implement
   `configure-environment()` function to set up the following variables for the given `variant`

   - `CLUSTER` - Kubernetes cluster name the variant should be deployed to, valid values are:
     - `cs1-dev`
     - `cs2-dev`
     - `cs1-prod`
     - `cs2-prod`
     - `ocp3-dev`
     - `ocp3-prod`
   - `NAMESPACE` - Kubernetes namespace the variant should be deployed in
   - `VALUE_FILES` - String array containing one or more value files to be applied. The path is relative to the
     individual site folder.

     The array can be set by individual index, and it's possible to reference files in other site folders:

     ```sh
     VALUE_FILES+=(
       "../shared/cs2-dev.yaml"
       "common-values.yaml"
       "my-values.yaml"
     )
     ```

     The order of the values file is important - when they contain the same fields, the later file will take precedence.

   - `BASE_IMAGE_TAG` - Tag of the `openshift/jenkins-ocp-anz` image to base the image from
   - `PLUGINS_FILE` - Optional. Path to the Jenkins `plugins.txt` file (relative to the individual site folder) for the
     plugins to be installed
   - `EXTRA_PARAMS` - Optional. String array container any extra parameters to be passed to the helm upgrade command
   - `RELEASE_NAME` - Optional. When set, use the specified name instead of the command line option.

<a name="determine-access-permissions"></a>

### Determine access permissions

The Jenkins instance is provisioned with OpenShift OAuth login, so that users with access to the namespace automatically
gets access to Jenkins. This is achieved with
[jenkins-openshift-login-plugin](https://github.com/openshift/jenkins-openshift-login-plugin).

By default, this plugin maps the openshift view/edit/admin role to Jenkins matrix, and by default:

- Users with the `view` role receive permissions `Overall-Read`, `Job-Read` and `Credentials-Read`
- Users with the `edit` role receive the following permissions in addition
  - `Job-Build`
  - `Job-Configure`
  - `Job-Create`
  - `Job-Delete`
  - `Job-Cancel`
  - `Job-Workspace`
  - `SCM-Tag`
- Users with the `admin` role can do everything

If the default behaviour is not suitable, this Helm chart provides a way to override it - see `customiseRoleMapping`
field in the values file. For example, the following values would grant users with `view` role the permission to run and
cancel builds:

```yaml
customiseRoleMapping:
  enabled: true
  mappings:
    # customise role mapping to grant user with 'view' role the ability to run and cancel jobs
    Job-Build: view,edit,admin
    Job-Cancel: view,edit,admin
```

Note - the mapping customisation is achieved by adding a config map named `openshift-jenkins-login-plugin-config` in the
namespace. If you are provisioning more than one Jenkins instances in the same namespace, make sure at most one of them
uses this feature to avoid conflicts.

<a name="anonymous-access"></a>

#### Anonymous access

By default the Jenkins instance would require authentication (through OpenShift OAuth) for all access.

For some teams it is desirable to allow anonymous access to the server (e.g. to view builds). This chart provided a
`anonymous-access-helper` groovy function to make enabling this easier.

To grant anonymous user read access to view builds, add the following to your site's values file:

```yaml
JCasC:
  configScripts:
    anonymous-access: |
      groovy:
         - script: |
            {{- .Files.Get "groovy-lib/anonymous-access-helper.groovy" | nindent 6 }}
            setAnonymousAccess(["Overall-Read", "Job-Read"] as String[])
```

**WARNING** - Jenkins does not have separate permission control for build logs (see
https://issues.jenkins.io/browse/JENKINS-3627). So even with just `Job-Read`, anonymous user would be able to view the
console outputs. So need to make sure that the applications' build/deploy logs does not contain sensitive information.

<a name="configuration-as-code"></a>

### Configuration as code

Configurations can be specified either with [config scripts](#config-scripts), or with the help of the
[default configs](#default-configs).

<a name="config-scripts"></a>

#### Config scripts

Arbitrary configuration can be specified in field `JCasC.configScripts` of the values file.

The example below sets up Kubernetes cloud

```yaml
JCasC:
  configScripts:
    k8s-clouds: |
      jenkins:
        clouds:
          - kubernetes:
              name: "dev"
              serverUrl: "https://kubernetes.default:443"
              namespace: "ib-ci"
              jenkinsUrl: "https://{{ include "jenkins.routeHost" $ }}"
              jenkinsTunnel: "{{ include "jenkins.jnlpServiceName" $ }}.{{ $.Release.Namespace }}.svc.cluster.local:{{ include "jenkins.jnlpPort" $ }}"
```

And this example sets up proxy

```yaml
JCasC:
  configScripts:
    master-proxy: |
      jenkins:
        proxy:
          name: "10.38.141.33"
          port: 80
          noProxyHost: |-
            *.service.dev
            *.test
            *.anz
            *.anznb.co.nz
```

More than one `configScripts` can be specified, either in the same values file or in different values files. Their
contents will be merged before being applied. Make sure there is no more than one config script setting the same
configuration, otherwise it will result in a conflict.

This example would cause JCasC error and resulting in configuration not being applied:

```yaml
JCasC:
  configScripts:
    master-proxy: |
      jenkins:
        proxy:
          name: "10.38.141.33"
    master-proxy-conflict: |
      jenkins:
        proxy:
          name: "127.0.0.1"
```

<a name="referencing-helm-values-and-variables"></a>

#### Referencing Helm values and variables

As seen in the `k8s-clouds` config script example above, the config scripts can reference the following to generate
configurations based on the release environment:

- All of [Helm built-in objects](https://helm.sh/docs/chart_template_guide/builtin_objects/), some useful examples
  - `Release` - e.g. getting the namespace `{{ .Release.Namespace }}`
  - `Values` - e.g. image tag: `{{ .Values.image.tag }}`
- All the variables defined in chart helper (`helm/templates/_helpers.tpl`). These needs to be referenced like this
  `{{ include "some.variable" $ }}`.

  Some useful variables:

  | Variable                     | Description                                                                                                             |
  | ---------------------------- | ----------------------------------------------------------------------------------------------------------------------- |
  | `jenkins.fullname`           | Full name of the Jenkins instance, which is also the name of most Kubernetes object (e.g. statefulset, route, PV, etc.) |
  | `jenkins.chart`              | Chart name and version as used by the chart label                                                                       |
  | `jenkins.image`              | Complete path to the Jenkins image, including repository, image and tag                                                 |
  | `jenkins.serviceAccountName` | Name of the service account used to run Jenkins master                                                                  |
  | `jenkins.routeHost`          | Fully qualified hostname for Jenkins                                                                                    |
  | `jenkins.jnlpServiceName`    | Name of the JNLP service                                                                                                |
  | `jenkins.jnlpPort`           | TCP port number of the JNLP service                                                                                     |
  | `jenkins.jcascConfigMapName` | Name of the JCasC config map                                                                                            |

<a name="default-configs"></a>

#### Default configs

The helm chart provided default JCasC config script to simplify common configurations.

To enable it, set `JCasC.defaultConfig` to `true`, and follow the instructions in the base `values.yaml` file to
configure your Jenkins instance.

For example, the following snippet configures the Jenkins pipeline libraries:

```yaml
JCasC:
  defaultConfig: true
  pipelineLibraries:
    openshiftPipeline:
      repo: https://bitbucket.nz.service.anz/scm/pipe/openshift-pipeline.git
      credentialsId: "bitbucket"
      includeInChangesets: true
    cspPipeline:
      repo: https://bitbucket.nz.service.anz/scm/dig/csp-pipeline.git
      credentialsId: "bitbucket"
      includeInChangesets: false
```

<a name="using-default-configs-together-with-custom-config-scripts"></a>

#### Using default configs together with custom config scripts

It's possible to use a combination of default config script and custom config scripts. The default config script would
skip sections when the custom script also defines it.

However there are a small number of default configuration values that you won't be able to override under
`configScripts` section, i.e:

```yaml
jenkins:
  mode: NORMAL
  numExecutors: 0
unclassified:
  location:
    url: https://example.com/jenkins
```

Apart from the above few fields, you can define any other configuration, and that will take precedence over the default
config. For example, with the following values file, the Jenkins instance will be configured with proxy `127.0.0.1:8080`
instead of `10.1.1.10:80`:

```yaml
JCasC:
  configScripts:
    proxy-override: |
      jenkins:
        proxy:
          name: "127.0.0.1"
          port: 8080

  defaultConfig: true

  master:
    proxy:
      name: "10.1.1.10"
      port: 80
```

<a name="seed-jobs-with-job-dsl"></a>

### Seed jobs with Job DSL

See [Job DSL documentation](https://github.com/jenkinsci/job-dsl-plugin/blob/master/docs/JCasC.md) on its support for
JCasC.

See also the Job DSL API for your specific Jenkins instance at <your-jenkins>/plugin/job-dsl/api-viewer/index.html.

A few shared groovy scripts are provided in the `helm/groovy-lib` folder and is packaged into the Helm chart to simplify
job setup. See its [README](./helm/groovy-lib/README.md) as well as comments in each groovy script on how to use it.

The job scripts are additive, so if there are common jobs between different variants in the same site, it's possible to
abstract it out like the following to avoid duplication:

```yaml
# common.yaml
JCasC:
  configScripts:
    common-jobs: |
      jobs:
        - script: |
            pipelineJob('common-job1') { }
# nonprod.yaml
JCasC:
  configScripts:
    nonprod-jobs: |
      jobs:
        - script: |
            multibranchPipelineJob('job2') { }
# prod.yaml
JCasC:
  configScripts:
    prod-jobs: |
      jobs:
        - script: |
            multibranchPipelineJob('job3') { }
```

Another way to share common job DSL is to leverage go template to reference defined values. The following example would
setup the `nonprod` and `prod` variants with the same multibranch job, but with different branch matching Regex:

```yaml
# common.yaml
JCasC:
  configScripts:
    common-jobs: |
      jobs:
        - script: |
            {{- .Files.Get "groovy-lib/multibranch-pipeline-helper.groovy" | nindent 6 }}
            def buildBranchRegex = '{{ .Values.branchRegex }}'
            bitbucketMultibranchPipelineJob(
              jobName: "ib-preauth",
              project: "DIG",
              repo: "preauth",
              credentialsId: "Bitbucket_ServiceAccount",
              branchRegex: buildBranchRegex,
            )
# nonprod.yaml
branchRegex: "PR-.*"
# prod.yaml
branchRegex: "^master$"
```

It's also possible to define script snippets and reference them like the following to further reduce duplication:

```yaml
# common.yaml
multiBranchJobSnippet: |
  bitbucketMultibranchPipelineJob(
    jobName: {{ .repo | quote }},
    project: "DIG",
    repo: {{ .repo | quote }},
    credentialsId: "Bitbucket_ServiceAccount",
    branchRegex: {{ $.Values.branchRegex | quote }},
  )
# nonprod.yaml
branchRegex: "PR-.*"
multibranchBuildRepos:
  - preauth
  - sam
JCasC:
  configScripts:
    nonprod-jobs: |
      jobs:
        - script: |
            {{- .Files.Get "groovy-lib/multibranch-pipeline-helper.groovy" | nindent 6 }}
            {{- range $key, $value := .Values.multibranchBuildRepos }}
              {{- $_ := set $ "repo" $value }}
              {{- tpl $.Values.multiBranchJobSnippet $ | nindent 6 }}
            {{- end }}
```

Notes:

- The `tpl` command is required only if the snippet contains go template (e.g. `{{ .repo | quote }}`)

  - Calling `tpl` inside `range` is a little tricky, see https://github.com/helm/helm/issues/5979

    Workaround is to patch the global context (`{{- $_ := set $ "repo" $value }}`) and pass that to the template

- As YAML is indentation-sensitive, make sure that the included scripts are indented correctly.

<a name="executing-groovy-scripts"></a>

### Executing groovy scripts

While not recommended (Jenkins settings should be updated using the declarative configuration-as-code), it is possible
to execute arbitrary groovy script as part of JCasC.

See https://github.com/jenkinsci/configuration-as-code-groovy-plugin

The Helm chart uses this feature to execute a script that will put the Jenkins instance into "quiet-down" / "preparing
for shut-down" mode when the `quietDown` is set to true in the values file.

<a name="enable-render-of-build-artifacts"></a>

### Enable render of build artifacts

By default Jenkins uses a rather strict `Content-Security-Policy`:

```http
Content-Security-Policy: sandbox; default-src 'none'; img-src 'self'; style-src 'self';
```

Which means HTML build artifacts such as test report would not render in Jenkins UI and browser reports errors such as:

> Blocked script execution in 'https://.../index.html' because the document's frame is sandboxed and the 'allow-scripts'
> permission is not set.

To reduce the strictness of the `Content-Security-Policy`, use a configuration like the following to run groovy script
to update the setting (this is only configurable via groovy script):

```yaml
JCasC:
  configScripts:
    content-security-policy: |
      groovy:
        - script: |
            System.setProperty("hudson.model.DirectoryBrowserSupport.CSP", "default-src 'self'; img-src 'self' data:; font-src 'self' data:;")
```

Note - depending on the test report generator, you may need slightly different CSP settings (e.g. allow
`'unsafe-inline'`). It's best to be as strict as possible when tweaking this to avoid potential security issue.

<a name="deploying"></a>

### Deploying

To deploy your site, you'll need to have `admin` role for the target cluster namespace, plus `edit` role for the
`digital-image-builds` namespace if the image does not already exist.

First login to the target OpenShift cluster that you are deploying to. For OpenShift 4, as username/password login is
disabled, you _must_ login through the Web UI and use the `Copy login command` (top right corner under your name):

| Cluster Name | Web Console                                                     |
| ------------ | --------------------------------------------------------------- |
| `cs1-dev`    | https://console-openshift-console.apps.cs1-dev.nz.service.test/ |
| `cs2-dev`    | https://console-openshift-console.apps.cs2-dev.nz.service.test/ |
| `cs1 (prod)` | https://console-openshift-console.apps.cs1.nz.service.anz/      |
| `cs2 (prod)` | https://console-openshift-console.apps.cs2.nz.service.anz/      |

```sh
oc login --token=<token> --server=https://api.cs1-dev.nz.service.test:6443
oc login https://caas-master.nz.service.test:8443
```

For production deployment, you will need to login to both the prod and non-prod clusters as the deploy script may need
to perform image promotion across clusters. Image migration would copy from the "equivalent" non-prod cluster as the
defined prod cluster, e.g.

- When `CLUSTER=cs1-prod`, image will be copied from `cs1-dev` cluster
- When `CLUSTER=cs2-prod`, image will be copied from `cs2-dev` cluster
- When `CLUSTER=ocp3-prod`, image will be copied from `ocp3-dev` cluster

Run the `deploy.sh` script to deploy or update your site:

```sh
./deploy.sh <site> <variant> [-r <release-name>]
```

where:

- `site` - name of the site to be deployed
- `variant` - name of the variant to be deployed
- `release-name` - Helm release name, which determines the names of the Kubernetes objects (statefulset, config maps,
  service account, etc.). Only needed if not already defined in site config

<a name="deleting-jenkins-instance"></a>

### Deleting Jenkins instance

!!WARNING!! - This will delete all objects provisioned by Helm, including the persistence volume. Proceed with caution.

To delete a Jenkins instance provisioned with this Helm chart, run the following command:

```sh
helm uninstall -n <namespace> <release-name>
```

OpenShift 4 clusters have native support for Helm, so this can also be done via the Web interface:

1. Login to the target OpenShift cluster
2. Select the namespace
3. Use the `Developer` view (rather than the `Administrator` view)
4. Wait for the `Helm` menu item to appear on the left hand side menu (which can take a few seconds after page load) and
   select it
5. Select `Uninstall Helm Release` option under the overflow menu for the instance that needs to be deleted

<a name="jenkins-openshift-pipeline-library"></a>

## Jenkins openshift-pipeline library

The [openshift-pipeline](https://bitbucket.nz.service.anz/projects/PIPE/repos/openshift-pipeline/browse) is an in-house
developed Jenkins pipeline library that provides common pipeline functionalities such as DriveTrain integration,
OpenShift deployment, canary, etc.

There are a few additional things that needs to be taken care of when provisioning Jenkins that uses the
`openshift-pipeline`

<a name="service-account-self-provisioner"></a>

### Service account self-provisioner

The `openshift-pipeline` creates temporary namespaces when building feature branches, so the service account it uses
(which is the same service account Jenkins master runs as) would require `self-provisioner` role to be granted.

The `self-provisioner` role needs to be granted by OpenShift cluster admin - raise a ticket with to them using this
link: https://jira.nz.service.anz/servicedesk/customer/portal/21/create/41 and provide information about the cluster,
namespace and service account name. You should only need this for non-prod clusters as that's where the branch builds
happen.

To find out the name of the service account, run command `oc get sa -n <namespace> -l release-name=<release name>`. For
example:

```sh
$ oc get sa -n ib-ci -l release-name=jenkins
NAME      SECRETS   AGE
jenkins   2         85d
```

### OpenShift cluster name

As part of the pipeline configuration, there is definition for the OpenShift cluster name. This is usually defined in
the `<Team>Defaults.groovy` file. The following example is taken from `CspDefaults.groovy`:

```groovy
  openshiftClusters: [
    dev : new OpenshiftCluster(
      name: 'openshift_non_prod', // this is the cluster name
      namespaceForSlaves: 'csp-ci',
    ),
    prod: new OpenshiftCluster(
      name: 'openshift_production',
      namespaceForSlaves: 'csp-production',
    ),
  ]
```

The cluster names defined there (with the `name` field) should match the cluster names defined in the Jenkins
configuration in this repo, e.g.:

```yaml
JCasC:
  openshiftClouds:
    openshift_non_prod: # this is the cluster name
      namespace: "csp-ci"
```

### Email configuration
It's recommended to use NZNP/NZ mail relays for setting up your Jenkins email notification, details as below

NZ: smtp.anz.co.nz, emails can be delivered to NZ (anz.co.nz) and Global (anz.com) addresses

NZNP: smtp.anznp.co.nz, emails can be delivered to NZNP (anznp.co.nz) and Globaltest addresses

Openshift clusters have been whitelisted thus you can use port 25 to send out emails without user authentication

To configure mailer, you can add the following block to your site JcasC config

```yaml
mailer:
  smtpHost: smtp.anznp.co.nz
  smtpPort: 25
```

You will also need to trust the cert from smtp.anz.co.nz by adding the following to your site config (not JcasC)

```yaml
jenkins_java_overrides: -Dmail.smtp.starttls.enable=true -Dmail.smtp.ssl.trust=smtp.anz.co.nz
```