# BWB site

The BWB site is for provisioning Jenkins instances used by Banker Workbench Platform teams. The main instances are in 
the `cs1`
clusters.

The following variants are supported:

| Variant          | Release name     | Cluster    | Description
| ---------------- | ------------     | ---------- | ------------------------------------------------------------------------------------------ |
| `nonprod`        | `bwb-jenkins`    | `cs1-dev`  | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup` | `bwb-jenkins`    | `cs2-dev`  | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`           | `bwb-jenkins`    | `cs1-prod` | Prod Jenkins instance for running master branch builds                                     |
| `prod-backup`    | `bwb-jenkins`    | `cs2-prod` | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default |

Release name is not specified in the config and needs to be provided to the deploy script with the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release name.

## Provision

### Update the non-prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh bwb nonprod-backup
./deploy.sh bwb nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh bwb nonprod
ENABLED=y ./deploy.sh bwb nonprod-backup
```

### Update the prod instance

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh bwb prod-backup
./deploy.sh bwb prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh bwb prod
ENABLED=y ./deploy.sh bwb prod-backup
```

### Regenerate service account token if required
If, as part of the deployment, you have had to delete the old Jenkins instance, rather than just updating it, then the 
Jenkins token in Vault will need to be updated.

To get the new token value log onto the Openshift Instance for the Jenkins you have just created.
E.g.:
```sh
oc login https://caas-master.nzlb.service.anz:8443 --token=#############
```
Change to BWB project (or bwb-tools or bwb-ci depending on the environment):
```sh
oc project bwb
```
Get the token:
```sh
oc sa get-token -n bwb bwb-jenkins
```
Once you have the token, update Vault:

Navigate to the bwb credentials in Vault (depending on project):
```sh
context/<bwb|bwb-ci|bwb-tools>/bwb-jenkins/credentials
```
Go to the service account entry:
```sh
openshift-service-account
```
And update the value with the new token.

### Windows Slave
BWB Windows slaves are provisioned as SSH agents in `common.yaml`. However, the manual configuration within 
windows machine still required to establish connection. You can find more information on this page: 
[Configure BWB Windows Slave](https://confluence.nz.service.anz/display/channels/How+to+setup+a+windows+slave+for+Jenkins/)
