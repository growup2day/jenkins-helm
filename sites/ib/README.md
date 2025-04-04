# IB site

The IB site is for provisioning Jenkins instances used by Internet Banking teams. The main instances are in the `cs2`
clusters.

The following variants are supported:

| Variant          | Release name | Cluster    | Description                                                                                |
| ---------------- | ------------ | ---------- | ------------------------------------------------------------------------------------------ |
| `dev`            |              | `cs2-dev`  | Personal Jenkins instance in namespace `ib-ci-dev`                                         |
| `dev-cs1`        |              | `cs1-dev`  | Personal Jenkins instance in namespace `ib-ci-dev`                                         |
| `nonprod`        | `jenkins`    | `cs2-dev`  | Main non-prod Jenkins instance for running pull-request builds                             |
| `nonprod-backup` | `jenkins`    | `cs1-dev`  | Backup non-prod Jenkins instance for running pull-request builds, in quiet mode by default |
| `prod`           | `jenkins`    | `cs2-prod` | Prod Jenkins instance for running master branch builds                                     |

Release name is not specified in the config and needs to be provided to the deploy script with the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release name.

## Provision

### Update the non-prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh ib nonprod-backup
./deploy.sh ib nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh ib nonprod
ENABLED=y ./deploy.sh ib nonprod-backup
```

**Post deployment task for non-prod only**

The IB and IBAT jobs have reference repo configured to improve the pipeline checkout performance for new PRs. This is to
address the issue caused by:

- IB repo is huge - around 2.6GB for a full clone
- IB nonprod Jenkins is using the merge strategy for building pull requests
- For all new pull requests, the first build would take over 3 minutes on Jenkins master just to do the cloning of the
  repository (in order to obtain the pipeline definition in `Jenkinsfile`) and it takes up 2.6GB space
  - Disk space adds up quickly as IB often has over 20 open pull requests

Run the following script on Jenkins master pod if it has not been done before:

```sh
if [[ ! -f /var/lib/jenkins/gitref/internetbanking ]]; then
  mkdir -p /var/lib/jenkins/gitref
  git clone https://bitbucket.nz.service.anz/scm/ib/internetbanking.git /var/lib/jenkins/gitref/internetbanking
fi
```
- This also needs to be run once on an openshift slave pod, if it has not been done before.
  - It needs to be one of the ephemeral openshift-pipeline slaves (eg. ib-batchjobs-pap-2165-batchjobs-jenkins-slave-1679704607--knjn3)
  - You can identify a relavent pod as it will have a PVC volume mounted to /var/lib/jenkins/gitref


You can use your personal BitBucket credential to perform the one-off clone.

Notes - This not needed for production because it only builds for a single branch (`master`). The job (configured with
reference repo) would still run when the reference repo folder doesn't exist, just means that the reference repo
configuration would not have any effect.

### Update the prod instance

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh ib prod-backup
./deploy.sh ib prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh ib prod
ENABLED=y ./deploy.sh ib prod-backup
```

### Create a new personal dev IB Jenkins instance

```sh
./deploy.sh ib dev -r <username>
```

Optional parameters can be passed in as environment variables:

- `BUILD_BRANCH_REGEX` - Set it to a non-blank value to seed your personal Jenkins instance with the same jobs of the
  non-prod IB Jenkins. All jobs will be set to build the branch or pull request matching the specified regex. Cannot be
  set to `master` and `PR-.*` as they are reserved for the prod and non-prod Jenkins instances.
- `DISABLED` - Set to `y` to put the Jenkins instance into "quiet-down" mode.

Examples:

```sh
# No jobs
./deploy.sh ib dev -r <username>
# Seed jobs building one branch
BUILD_BRANCH_REGEX=my-branch ./deploy.sh ib dev -r <username>
# Seed jobs building one pull request
BUILD_BRANCH_REGEX=PR-123 ./deploy.sh ib dev -r <username>
```


#### Vault credential for personal Jenkins

Configure necessary credentials in the `nonprod` namespace of [NZ Vault](https://vault.nzlb.service.anz:8200/).

The following are required to run IB/IBAT/Preauth builds:

- path `context/ib-ci-dev/<username>-jenkins/pairs/Bitbucket_ServiceAccount`
  - `username` - use your BitBucket username
  - `password` - personal access token (**DO NOT** use password, unless you want to risk it being leaked). Personal
    access token can be generated on BitBucket:
    - Login into https://bitbucket.nz.service.anz/
    - Click on your user profile (top right) and choose `Manage account`
    - Select `Personal access token` -> `Create a token`
    - Enter name of the token so you know the purpose of this token should you need to revoke it. e.g.
      `personal-jenkins`
    - Give it only read permissions
- path `context/ib-ci-dev/<username>-jenkins/pairs/artifactory-api-key`
  - `username` - use your artifactory username
  - `password` - generate your API key by
    - Login into https://artifactory.nz.service.anz/
    - Go to your user profile, enter password again to `Unlock`
    - Generate API key and copy the content
- path `context/ib-ci-dev/<username>-jenkins/keys`
  - `dependency-track-api-key` - copy value from `context/ib-ci/jenkins/keys`
  - `fortify-ci-token` - generate token by
    - Login into https://appau001mel0909.global.anz.com/ssc/
    - Go to `Administration` -> `Users` -> `Token Management`
    - Click `New`, select `CI Token` as token type
    - Enter description of the token so you know the purpose of this token should you need to revoke it. e.g.
      `personal-jenkins`
    - Copy the decoded token (that looks like a GUID)
  - `checkmarx-token` - generate token by:
    - Follow the guide at
      https://confluence.service.anz/display/SIC/Secure+Code+Review+-+User+Guide#849749856aca97a8b2bbc40cda192df0e36c4c81f
      - A generate token section is under the Scanning tab.
      - Basically you run:
      ```sh
      docker run --rm --entrypoint=/usr/bin/java secure-coding-ci-docker.artifactory.gcp.anz/cx-cli \
          -jar /opt/cxcli/CxConsolePlugin-CLI.jar generatetoken \
          -cxuser global\\${user}  \
          -cxserver https://dcxcheckmarx.service.anz \
          -cxpassword ${pass}
      ```
    - Enter description of the token so you know the purpose of this token should you need to revoke it. e.g.
      `personal-jenkins`
    - Copy the decoded token (that looks like a GUID)
