# Sample site

The sample site is used to demonstrate the features of the Jenkins helm chart. The following variants are supported:

| Variant         | Release name    | Cluster    | Description                                                   |
| --------------- | --------------- | ---------- | ------------------------------------------------------------- |
| `blank`         |                 | `cs2-dev`  | Blank Jenkins instance with no customisation at all           |
| `blank3`        |                 | `ocp3-dev` | Blank Jenkins instance with no customisation at all           |
| `plugins`       | `plugins`       | `cs2-dev`  | Jenkins instance with extra plugins installed                 |
| `jcasc-basic`   | `jcasc-basic`   | `cs2-dev`  | Jenkins instance configured with custom config scripts        |
| `jcasc-default` | `jcasc-default` | `cs2-dev`  | Jenkins instance configured with default JCasC config scripts |

All samples will be deployed to the `jenkins-helm` namespace. When release name is not specified in the config, it needs
to be provided to the deploy script with the `-r|--release-name` parameter. In which case multiple instances of the same
variant can be provisioned with different release name.
