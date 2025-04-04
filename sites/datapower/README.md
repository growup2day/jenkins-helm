# Datapower site

The Datapower site is for provisioning Jenkins instances used by Datapower team.

The following variants are supported:

| Variant          | Release name     | Cluster    | Description
| ---------------- | ------------     | ---------- | ------------------------------------------------------------------------------------------ |
| `nonprod`        | `jenkins-dp`      | `cs1-dev`  | Main non-prod Jenkins instance for running builds on non-prod datapower devices                             |
| `nonprod-backup` | `jenkins-dp`      | `cs2-dev`  | Backup non-prod Jenkins instance for running all builds on non-prod datapower devices, in quiet mode by default |
| `prod`           | `jenkins-dp`      | `cs1-prod` | Prod Jenkins instance for running builds on prod datapower devices                                  |
| `prod-backup`    | `jenkins-dp`      | `cs2-prod` | Backup Prod Jenkins instance for running builds on prod datapower devices, in quiet mode by default |

Default release names have been specified in the config and can be overridden by the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release names.

## Provision

### Update the non-Prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh datapower nonprod-backup
./deploy.sh datapower nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh datapower nonprod
ENABLED=y ./deploy.sh datapower nonprod-backup
```

### Update the Prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh datapower prod-backup
./deploy.sh datapower prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh datapower prod
ENABLED=y ./deploy.sh datapower prod-backup
```
### Note

Please note to change the vault mountPath as per the cluster (CS1 and CS2) in nonprod.yaml and prod.yaml before deployment.

The base image for datapower jenkins is different from other sites using helm chart for jenkins.
The previous Jenkins instance, deployed on OCP3 , didn't have a master-slave concept, and everything bonded to the master node. The services developed by Integration dev team, which are deployed by this jenkins instance to datapower, also expect the master node to have all the binaries installed. So, the base image was expected to have all the required binaries for their node js projects. This has been discussed with Hydra hawks. Also, the previous ansible version of jenkins deployment, provided an option of uploading files to Jenkins during deployment. Some of the binaries like dpbuddy (java project), used by datapower ops pipeline jobs have been added to the master node in that way. Since Jenkins-helm does not offer a role like this, we decided to incorporate the additional binaries needed in the base image and built the image on top of jenkins-ocp-anz image.

We have created a base image using bitbucket repo: https://bitbucket.nz.service.anz/projects/DIGIMG/repos/datapower-jenkins/browse
(jenkins for digital image build:
Master branch: https://jenkins-digital-image-builds.apps.cs1.nz.service.anz/job/DIGIMG/job/datapower-jenkins/ )
