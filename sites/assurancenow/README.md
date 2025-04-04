# AssuranceNow site

The AssuranceNow site is for provisioning Jenkins instances used by AssuranceNow.

The following variants are supported:

| Variant          | Release name | Cluster   | Description                                                                                    |
| ---------------- | ------------ | --------- | ---------------------------------------------------------------------------------------------- |
| `nonprod`        | `jenkins`    | `cs1-dev` | Main non-prod Jenkins instance for running all pull-request builds                             |
| `nonprod-backup` | `jenkins`    | `cs2-dev` | Backup non-prod Jenkins instance for running all pull-request builds, in quiet mode by default |
| `prod`           | `jenkins`    | `cs1`     | Prod Jenkins instance for running master branch builds                                         |
| `prod-backup`    | `jenkins`    | `cs2`     | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default        |

All instances are deployed to the `assurancenow-ci` namespace. Multiple instances of the same variant can be provisioned
with different release name by using `-r|--release-name`.

## Provision

### Update the non-prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh assurancenow nonprod-backup
./deploy.sh assurancenow nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh assurancenow nonprod
ENABLED=y ./deploy.sh assurancenow nonprod-backup
```

### Update the prod instance

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh assurancenow prod-backup
./deploy.sh assurancenow prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh assurancenow prod
ENABLED=y ./deploy.sh assurancenow prod-backup
```
