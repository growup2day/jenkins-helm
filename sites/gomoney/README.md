# goMoney site

The goMoney site is for provisioning Jenkins instances used by goMoney teams.

| Variant          | Release name | Cluster   | Description                                                                                                          |
|------------------|--------------|-----------|----------------------------------------------------------------------------------------------------------------------|
| `personal`       |              | `cs1-dev` | Personal Jenkins test instance in namespace `gomoney-jenkins-dev`                                                    |
| `dev`            | `jenkins`    | `cs1-dev` | Shared Jenkins test instance in namespace `gomoney-jenkins-dev`                                                      |
| `nonprod`        | `jenkins`    | `cs2-dev` | Main non-prod Jenkins instance for running pull-request builds in namespace `gomoney-ci`                             |
| `nonprod-backup` | `jenkins`    | `cs1-dev` | Backup non-prod Jenkins instance for running pull-request builds, in quiet mode by default in namespace `gomoney-ci` |
| `prod`           | `jenkins`    | `cs2`     | Main prod Jenkins instance for running master branch builds in namespace `gomoney-ci`                                |
| `prod-backup`    | `jenkins`    | `cs1`     | Backup prod Jenkins instance for running master branch builds, in quiet mode by default in namespace `gomoney-ci`    |

### Logging in to OpenShift

Browse to either of these links to obtain a valid login command for CS1 or CS2 cluster:

- https://oauth-openshift.apps.cs1-dev.nz.service.test/oauth/token/request
- https://oauth-openshift.apps.cs2-dev.nz.service.test/oauth/token/request

Use the `oc login` command line provided in those links in your terminal session to login to OpenShift.

### Create a new personal dev goMoney Jenkins instance

Log into CS1 OpenShift per the `Logging in to OpenShift` section.

```sh
./deploy.sh gomoney personal --release-name <username>
```

For example, if your username was `andrewb` you would run:

```
./deploy.sh gomoney personal --release-name andrewb
```

### Switch Non Prod instances, moving the backup to primary and primary to backup

Log into CS2 OpenShift per the `Logging in to OpenShift` section and run:

```sh
DISABLED=y ./deploy.sh gomoney nonprod
```

Log into CS1 OpenShift per the `Logging in to OpenShift` section and run:

```
ENABLED=y ./deploy.sh gomoney nonprod-backup
```

### Deploying Jenkins

> Note: The release name defaults as `jenkins` so no need to specify it.

Prior to running these scripts you will need to be logged into OpenShift CS1 or CS2 in your CLI,
depending on which deployment you need to do.

| Cluster | Deployment Type   | Deployment Command                   |
|---------|-------------------|--------------------------------------|
| CS1     | Non Prod - Dev    | `./deploy.sh gomoney dev`            |
| CS2     | Non Prod          | `./deploy.sh gomoney nonprod`        |
| CS1     | Non Prod - Backup | `./deploy.sh gomoney nonprod-backup` |
| CS2     | Prod              | `./deploy.sh gomoney prod`           |
| CS1     | Prod - Backup     | `./deploy.sh gomoney prod-backup`    |

> Important: Before deploying to a Jenkins instance it is recommended to put it into `Shut Down` mode to
> prevent any jobs from running.
>
> It is also **highly recommended** that after running a deployment, the Jenkins
> instance should be restarted to ensure it is in a deterministic state. This can be done by appending
> `/restart` to the Jenkins URL of the Jenkins instance.
> 
> If you are deploying to a Jenkins instance that is in shut down mode, but for some reason still has
> a queue of pending jobs on it (shouldn't have any if it is in shut down mode) go to the `Script Console`
> inside the Jenkins administration page and run `Jenkins.instance.queue.clear()` to clear them. 
