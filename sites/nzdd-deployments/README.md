# NZDD Jenkins Pipeline site

The `nzdd-deployments` site is for provisioning Jenkins instances used by the New Zealand Data Delivery teams.

The following variants are currently supported:

| Variant          | Release name   | Cluster    | Description                                                                                                         |
| ---------------- | -------------- | ---------- | ------------------------------------------------------------------------------------------------------------------- |
| `cs1-dev`        | `jenkins`      | `cs1-dev`  | Stable non-prod Jenkins instance `nzdd-deployments.apps.cs1-dev.nz.service.test` for Data Delivery (FUTURE STATE)   |
| `cs2-dev-test`   | `jenkins`      | `cs2-dev`  | Unstable non-prod Jenkins instance `nzdd-deployments-test.apps.cs2-dev.nz.service.test` for Data Delivery           |
| `cs1-prod`       | `jenkins`      | `cs1-prod` | Primary PRODUCTION Jenkins instance `nzdd-deployments.apps.cs1.nz.service.anz` for Data Delivery                    |
| `cs2-prod-test`  | `jenkins`      | `cs2-prod` | Secondary PRODUCTION Jenkins instance `nzdd-deployments-test.apps.cs2.nz.service.anz` for Data Delivery             |

## Using the run.sh script

The `run.sh` script is a helper script for running common tasks related to the Helm chart. It's mainly used during development to avoid having to remember specific commands. Before running the script, make sure you're logged into the correct OpenShift cluster and have switched to the correct project.

### Getting Help

The `run.sh` script has in-built help which can be displayed by simply running the script without any parameters or by running `./run.sh help`. This will list out all the available sub-commands you can use.

To use the script, execute `./run.sh <action>`, replacing `<action>` with one of the sub-commands listed in the help. For example, to compile the Helm chart, you would run `./run.sh compile`. We recommend using the alias command to streamline this.

### Deploying the site

To deploy the `nzdd-deployments` Jenkins instance we use the `run.sh` script, since there are some post deployment activities that need to be performed. Typically, while testing, we can just use the default settings (which deploys to CS2-DEV), but this can be changed by setting the `DEPLOY_ENV` environment variable.

```shell
# Deploy to CS2-DEV
./run.sh deploy

# Deploy to CS1-DEV
DEPLOY_ENV="cs1-dev" ./run.sh deploy
```

This makes any non-dev deployment environment intentional and also means the defaults can be overridden in a Jenkins pipeline (for example if we had a pipeline to deploy the instance). The values for `DEPLOY_ENV` match the variants in the `config.sh` file.

#### Post Deployment Actions

Since we're using our bespoke `run.sh` script to deploy, we can add any additional post-deployment actions if necessary. Currently, we are only copying over the configuration file for the Build Failure Analyser plugin. We should only resort to this option if there are not better options to solve the problem so please exhaust all other avenues first.

#### Additional Notes on run.sh

- The `deploy` sub-command wraps the `deploy.sh` script in the project root folder so any changes to that script will effect the `run.sh` script.
- The `deploy` sub-command will attempt to compile the template before attempting to deploy. This is to ensure the template syntax is correct and to provide immediate feedback if something hasn't been formatted properly.
- There are several pod sub-commands, one notable one is `pod-watch`. It can be useful to watch a pod's complete lifecycle when troubleshooting. The `pod-watch` sub-command will poll OpenShift until the pod comes online and then start streaming the logs. If the pod is terminated, the logs will continue to stream until the pod has died at which point the `pod-watch` sub-command will automatically start polling OpenShift until the pod comes back online.
- The `docker-test` and `docker-tty` commands run the older version of the Helm UnitTest package which is used by the Jenkins Helm repo. Tests written in the newer version of the UnitTest package are not backwards compatible and often fail in the older version so the Docker commands have been added for your convenience. You can use the `install-plugins` sub-command to install the older version of the UnitTest plugin on your local machine if you prefer.


### Available Actions

For the most up-to-date list of commands, run `./run.sh`.

- `alias`: Prints out the command to set an alias for this script.
- `compile`: Compiles the Helm chart and displays the output.
- `deploy`: Deploys the Helm chart to OpenShift using the `deploy.sh` script.
- `docker-test`: Runs the unit tests inside a Docker container.
- `docker-tty`: Runs a Docker container and starts an interactive bash shell.
- `install-plugins`: Installs the correct (old) version of the Jenkins Helm plugin.
- `pod-delete`: Deletes the pod to force its recreation.
- `pod-kill`: Same as `pod-delete`.
- `pod-rsh`: Connects a terminal session to the pod.
- `pod-watch`: Continuously watches the pod logs. If the pod is deleted, it will continue to watch until the pod comes back online.
- `template`: Compiles the template locally (without connecting to OpenShift).
- `test`: Runs the unit tests.
- `uninstall`: Uninstalls the Jenkins Helm chart.
- `update-snapshot`: Updates the snapshot of the unit tests.
- `upload`: Uploads files in the `UPLOAD_FILES` array into the pod.

## Folder Structure

Although Helm makes maintaining Jenkins infrastructure significantly simpler, it can be difficult to find the correct values to change when things need to be changed because values are spead across multiple files. To reduce this complexity, we have opted to put values that may change in an **answer** file which is simply identified by the environment name, i.e. `cs2-dev-test.yaml`. Some values may be duplicated between the different environment answer files, but since these values are centrally located in these files, it makes it easy to update just in these files (rather than across many files).

Configuration that is consistent across both DEV and PROD environments are stored in the `common.yaml` file and anything common to DEV environments are stored in the `nonprod.yaml` files. For better readability, credentials, jobs and pod templates have split out into separate files based on their environment.

We intend to keep the plugin list consistent across both DEV and PROD environments.

## Jenkinsfile

The Jenkinsfile in this site is for the Automated deployment of nzdd-deployments to the OpenShift namespaces nzdd-jenkins-dev and nzdd-jenkins-prod in both the CS1 and CS2 clusters (dev/prod).
We have a seperate OpenShift namespace for running this Jenkins pipeline, nzdd-opps, which we plan to add a site in Jenkins Helm in the future.
Currently the Jenkinsfile is a work in progress and is not ready for use.