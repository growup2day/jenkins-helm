# Integration Services site

The Integration Services site is for provisioning Jenkins instances used by Integration Fastify Services teams.

The following variants are supported:

| Variant          | Release name     | Cluster    | Description
| ---------------- | ------------     | ---------- | ------------------------------------------------------------------------------------------ |
| `nonprod`        | `jenkinscd`      | `cs1-dev`  | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup` | `jenkinscd`      | `cs2-dev`  | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`           | `jenkinscd`      | `cs1-prod` | Prod Jenkins instance for running master branch builds                                  |
| `prod-backup`    | `jenkinscd`      | `cs2-prod` | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default |

Release name is not specified in the config and needs to be provided to the deploy script with the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release name.

## Provision

### Update the non-prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh integration-services nonprod-backup
./deploy.sh integration-services nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh integration-services nonprod
ENABLED=y ./deploy.sh integration-services nonprod-backup
```

### Update the prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh integration-services prod-backup
./deploy.sh integration-services prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh integration-services prod
ENABLED=y ./deploy.sh integration-services prod-backup
```
