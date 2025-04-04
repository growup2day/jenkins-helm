# Contributing Guidelines

Contributions are welcome via pull requests.

## How to Contribute

1. Clone this repository
2. Develop, and test your changes in a branch
3. Submit a pull request

You'll need some understanding of the following technologies, all very well documented:

- [Helm](https://helm.sh/docs/chart_template_guide/getting_started/)
  - [Go templates](https://pkg.go.dev/text/template)
  - [Sprig library](https://masterminds.github.io/sprig/)
- [Jenkins Configuration as Code (a.k.a. JCasC) plugin](https://github.com/jenkinsci/configuration-as-code-plugin)
- [Job DSL plugin](https://github.com/jenkinsci/job-dsl-plugin)
  - Its [integration with JCasC](https://github.com/jenkinsci/job-dsl-plugin/blob/master/docs/JCasC.md)
  - Some good [example DSL scripts](https://github.com/sheehan/job-dsl-gradle-example) to learn from
  - [Job DSL Playground](http://job-dsl.herokuapp.com/) - App for debugging Job DSL scripts.
- [JCasC groovy plugin](https://github.com/jenkinsci/configuration-as-code-groovy-plugin)

Refer to [Jenkins helm-charts](https://github.com/jenkinsci/helm-charts) (by which this project is inspired) for sample
implementation.

## Local Development

### Prerequisites

1. Command line tools (all can be provisioned with
   [ANZ Developer Setup ansible scripts](https://bitbucket.nz.service.anz/projects/DS/repos/ansible/browse))
   - [git](https://git-scm.com/)
   - [OpenShift Client v4](https://docs.openshift.com/container-platform/4.7/cli_reference/openshift_cli/getting-started-cli.html)
   - [helm](https://helm.sh/docs/intro/install/)
   - [skopeo](https://github.com/containers/skopeo)
2. [helm-unittest](https://github.com/quintush/helm-unittest)

   ```sh
   helm plugin install https://github.com/quintush/helm-unittest
   ```

### Recommended editor

Visual Studio Code with the recommended extensions (see `.vscode/extensions.json`).

### Running unit test

Run the following command to execute tests.

```sh
./test.sh
```

Many unit tests uses snapshot testing, to accept the change and update the snapshots, run the following command:

```sh
./test.sh -u
```

The committed snapshots will show up in the pull request to help the reviewer to see the effect of the change.

## Design

### Image building

**Goals**

1. Independence - Different sites and even variants within a site can have its own unique requirement on the version of
   Jenkins and plugins without interfering with other sites/variants.
2. Maximum reuse - When two sites/variants have identical requirements, same image is reused to avoid unnecessary
   rebuilds.

**Implementation**

All image builds share the same `jenkins-helm` build config in namespace `digital-image-builds`, and the same
`digital-image-builds/jenkins-helm` image stream.

The Jenkins image is build from the `openshift/jenkins-ocp-anz` base image that is maintained by the ANZ OpenShift team.
See their [BitBucket repo](https://bitbucket.nz.service.anz/projects/OP/repos/jenkins/browse).

Each site defines their own base image version (`BASE_IMAGE_TAG`) and the list of plugins (`PLUGINS_FILE`) via the
config script, so each team can have separate cadence with updating their Jenkins instance.

The output image will be tagged with a combination of:

- Base image tag (e.g. `v4.7.2`)
- Unique signature for the list of plugins if specified
  - the signature is generated with a SHA256 of the plugins file, with
    - all comments and empty lines removed
    - list of plugins sorted alphabetically
  - so that the signature is deterministic for a given set of plugins

Image is only built if there does not exist an image with the same tag.

Example image tags:

- `v4.7.2-bbf62be158bc4902b553f813afa35c5ad6dfb96679d9159f833ab753dd162a0f`
- `v4.7.2` - if no plugins specified

### Default JCasC script

While JCasC is very flexible to configure every Jenkins configuration, the default JCasC script provides 2 benefits:

1. Simpler values file for common configurations

   This is achieved by reducing repetition (e.g. `JCasC.permanentNodes.commonAttributes`) and providing sensible default
   or even hardcoded values (e.g. BitBucket URL).

2. Better support for DRY (don't repeat yourself) principle

   This is achieved by exposing object/map data structure instead of arrays, as arrays could not be easily merged.

   For example, a site with `nonprod` and `prod` variants may have some common Vault credentials and some variant
   specific ones. Because in JCasC the credentials is an array, the 2 variants would need to define the complete set of
   credentials:

   ```yaml
   # nonprod.yaml
   credentials:
     - vaultUsernamePasswordCredentialImpl:
         id: "common-1"
         path: "secret/context/path/to/common-1"
         scope: GLOBAL
     - vaultUsernamePasswordCredentialImpl:
         id: "nonprod-1"
         path: "secret/context/path/to/nonprod-1"
         scope: GLOBAL
   # prod.yaml
   credentials:
     - vaultUsernamePasswordCredentialImpl:
         id: "common-1"
         path: "secret/context/path/to/common-1"
         scope: GLOBAL
     - vaultUsernamePasswordCredentialImpl:
         id: "prod-1"
         path: "secret/context/path/to/prod-1"
         scope: GLOBAL
   ```

   And with the help of the default script, the common credentials can be refactored out into a common file, e.g.:

   ```yaml
   # common.yaml
   credentials:
     common-1:
       kind: vaultUsernamePasswordCredentialImpl
       path: "secret/context/path/to/common-1"
       scope: GLOBAL
   # nonprod.yaml
   credentials:
     nonprod-1:
       kind: vaultUsernamePasswordCredentialImpl
       path: "secret/context/path/to/nonprod-1"
       scope: GLOBAL
   # prod.yaml
   credentials:
     prod-1:
       kind: vaultUsernamePasswordCredentialImpl
       path: "secret/context/path/to/prod-1"
       scope: GLOBAL
   ```

#### Adding to default JCasC scripts

To support easier configuration for a section that's not yet covered, add a default JCasC script with the following
steps:

1. Add a new `.tpl` file in folder `helm/templates/jcasc-default-config/`, make sure the file name starts with
   underscore (`_`) as per Helm's convention for
   [files without k8s manifest](https://helm.sh/docs/chart_template_guide/named_templates/#partials-and-_-files)
2. Use an existing file as reference and define a template with name prefixed by `jenkins.casc.defaults.`. Add the new
   template name (without the prefix) to the list in file `helm/templates/config-jcasc.yaml`.
3. For JCasC content, an easy way would be to configure a dummy Jenkins master manually, and view/download the active
   JCasC configuration (by going to `Manage Jenkins` -> `Configuration as Code`)
4. Best practices:
   - Check for custom script overrides, and don't generate any content if override is found, e.g.
     ```go
     {{- $configScripts := toYaml .Values.JCasC.configScripts -}}
     {{- if not (contains "bitbucketEndpointConfiguration:" $configScripts) }}
     ```
   - Document the equivalent configuration section on Jenkins UI with YAML comment
   - When applicable, provide a toggle to enable/disable the Jenkins feature. The toggle can be either explicit, or
     implicit (based on whether a value is defined or not). When disabled, generate a JCasC config that would reset any
     existing configuration to a default state (e.g. for proxy, the default state would be no proxy).
5. Add unit test in folder `helm/unittests/jcasc-default-config/` for the new section. Minimum of 3 scenarios should be
   tested (more if the template logic is complex):
   1. That the generated config matches the specified values
   2. That it generates correct config for the default state
   3. That no config is generated when the same section is defined in custom scripts
