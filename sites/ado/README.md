# ADO site

The ADO site is for provisioning the production Jenkins used by the ADO dev and support teams.

The following variants are supported:

| Variant          | Cluster    | Description
| ---------------- | ---------- | ------------------------------------------------------------------------------------------ |
| `cs1-dev`        | `cs1-dev`  | Dev instance on dev CS1 cluster, mainly used for development and testing of new versions of the prod Jenkins instance. Can be used to manage the Dev & Test1/2/3 regions. |
| `cs2-dev`        | `cs2-dev`  | Dev instance on dev CS2 cluster. Either cluster instance can be used if the other is unavailable. |
| `cs1-prod`       | `cs1-prod` | Prod Jenkins instance on prod CS1 cluster. Used for OAT and production deployments/health checking. |
| `cs2-prod`       | `cs2-prod` | Prod instance on prod CS2 cluster. Either cluster instance can be used if the other is unavailable. |

## Prerequisites
1. A linux VM
2. The right AD groups on your globaltest and global accounts. Details can be found [here.](https://confluence.nz.service.anz/display/adlo/Production+Jenkins+Development#ProductionJenkinsDevelopment-RequiredADGroups)
3. The OpenShift v4 oc client. You can get this from the OpenShift console, e.g. [the dev cs1 one.](https://console-openshift-console.apps.cs1-dev.nz.service.test/command-line-tools)
4. [helm](https://helm.sh/docs/intro/install/)
5. [skopeo](https://github.com/containers/skopeo)

## Deploying a new Jenkins version

First use the oc client to log into the appropriate cluster. OS4 only supports a token based oc login; you can get the exact login command from these URLs:
 - Dev CS1: https://oauth-openshift.apps.cs1-dev.nz.service.test/oauth/token/request
 - Dev CS2: https://oauth-openshift.apps.cs2-dev.nz.service.test/oauth/token/request
 - Prod CS1: https://oauth-openshift.apps.cs1.nz.service.anz/oauth/token/request
 - Prod CS2: https://oauth-openshift.apps.cs2.nz.service.anz/oauth/token/request

The OpenShift namespace used by deploy.sh set to ado-ci. You can override this by changing the NAMESPACE value set in the ado site's [config.sh](config.sh).

To deploy the configuration under the ado site and create the corresponding running instance of Jenkins in the ado-ci namespace, run the
[deploy.sh](../../deploy.sh) script with the appropriate variant for the cluster as needed. E.g. 

```sh
./deploy.sh ado cs1-dev
```

New versions should be deployed and tested in the dev clusters before being deployed to the production clusters. Always deploy to both the cs1 and cs2 clusters 
to keep them in sync.

## How deploy.sh works

It pays to read [the main README.md](../../README.md), but the summary is that the [deploy.sh](../../deploy.sh) script will do a few things:
1. Analyse the ado site's [plugins.txt](plugins.txt) and build a new customised ANZ Jenkins image if needed. If the plugins.txt file hasn't changed then this 
step will be skipped. 
2. Migrate the image from the dev docker repo to the prod docker repo using skopeo if performing a prod deployment and the image hasn't previously been 
migrated.
3. Combine all the yaml config under helm/templates and sites/ado for the supplied variant and run a helm chart deployment into the ado-ci namespace. The
ado yaml files that get used for each variant is defined by the ado site's [config.sh](config.sh), which is sourced by the [deploy.sh](../../deploy.sh) script.

## How the yaml config works

Helm will upload the configuration for the jenkins pod, service, route, persistent volume, etc. to openshift. The deploy process also creates and uploads 
openshift config map definitions containing all the Jenkins Configuration as Code (JCasC) config. The config maps are then loaded by the JCasC plugin to define 
all the Jenkins configuration like credentials, slaves, jobs, etc.

The JCasC config defined under the "configScripts" sections is mapped into openshift config maps as is, however other JCasC config items like permanentNodes, 
envVars, etc. are transformed into the actual JCasC config using the go templates under [helm/templates](../../helm/templates). The documentation on how to 
define the template appropriate config is in the [values.yaml](../../helm/values.yaml). See [config-jcasc.yaml](../../helm/templates/config-jcasc.yaml) for the
logic that performs the go template injection.

Additionally, it's possible for the JCasC plugin to run groovy scripts that define Jenkins configuration. The jobs defined in the ado site's 
[common.yaml](common.yaml) are created this way. 

You can see what yaml will be uploaded by helm by running with the -d dry run flag:

```sh
./deploy.sh -d ado cs1-dev
```

New helm deployments will trigger the JCasC plugin to reload the config maps via [a custom python util script](../../helm/utils/reload-config-on-change.py). The
plugin will sync the current Jenkins configuration with the newly uploaded configuration, so any manual changes made in Jenkins itself will be wiped, updates 
will be applied as needed, and previously defined Jenkins items like credentials and slaves will be removed if they no longer exist in the new JCasC config. The
exception to this is the config applied via groovy scripts such as job definitions.

## Vault Integration

| Clusters              | Vault Namespace | Base Secret Path                   | URL                                                                           |
| --------------------- | --------------- | ---------------------------------- | ----------------------------------------------------------------------------- |
| `cs1-dev` `cs2-dev`   | nonprod         | /secret/context/ado-ci/ado-jenkins | https://vault.nzlb.service.anz:8200/ui/vault/auth?namespace=nonprod&with=ldap |
| `cs1-prod` `cs2-prod` | prod            | /secret/context/ado-ci/ado-jenkins | https://vault.nzlb.service.anz:8200/ui/vault/auth?namespace=prod&with=ldap    |

Access to the Vault UI for viewing or loading credentials under the /secret/context/ado-ci path is controlled by AD groups. See 
[here](https://confluence.nz.service.anz/display/adlo/Production+Jenkins+Development#ProductionJenkinsDevelopment-RequiredADGroups) for more details.

The ADO Jenkins instances pull secrets from Vault using the Vault plugin. A Vault policy allows the ado-jenkins service account to use the vault-auth credential
to access any secrets in Vault under /secret/context/<OpenShift namespace>/<Service Account Name>, e.g. /secret/context/ado-ci/ado-jenkins.

## Useful links

[JCasC documentation](https://ado-jenkins-ado-ci.apps.cs1-dev.nz.service.test/configuration-as-code/reference)


