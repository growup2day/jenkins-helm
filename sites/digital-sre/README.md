# Digital SRE site

The Digital SRE is for provisioning Jenkins instances used by the Digital SRE team for operational job automation. The
main instances are in the `cs1` clusters.

The following variants are supported:

| Variant          | Release name | Cluster    | Description                                                                                                       |
| ---------------- | ------------ | ---------- | ----------------------------------------------------------------------------------------------------------------- |
| `nonprod`        | `jenkins`    | `cs1-dev`  | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup` | `jenkins`    | `cs2-dev`  | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`           | `jenkins`    | `cs1-prod` | Prod Jenkins instance for running master branch builds                                                            |
| `prod-backup`    | `jenkins`    | `cs2-prod` | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default                           |

Release name is not specified in the config and needs to be provided to the deploy script with the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release name.

## Provision

### Update the non-prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh digital-sre nonprod-backup
./deploy.sh digital-sre nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh digital-sre nonprod
ENABLED=y ./deploy.sh digital-sre nonprod-backup
```

### Update the prod instance

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh digital-sre prod-backup
./deploy.sh digital-sre prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh digital-sre prod
ENABLED=y ./deploy.sh digital-sre prod-backup
```

```

```
