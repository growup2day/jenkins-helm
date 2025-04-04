# Integration site

The Integration site is for provisioning Jenkins instances used by Integration teams.

The following variants are supported:

| Variant          | Release name     | Cluster    | Description
| ---------------- | ------------     | ---------- | ------------------------------------------------------------------------------------------ |
| `nonprod`        | `jenkinscd`      | `cs1-dev`  | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup` | `jenkinscd`      | `cs2-dev`  | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`           | `jenkinscd`      | `cs1-prod` | Prod Jenkins instance for running master branch builds                                  |
| `prod-backup`    | `jenkinscd`      | `cs2-prod` | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default |

Default release names have been specified in the config and can be overridden by the `-r|--release-name`
parameter. Multiple instances of the same variant can be provisioned with different release names.

## Provision

### Update the non-Prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh integ nonprod-backup
./deploy.sh integ nonprod
```

By default when no additional parameter is provided, the main instance is active and the backup instance is provisioned
in "quiet-down" mode where it would not execute builds.

The backup instance is provided in case where the main instance is not available for whatever reason (e.g. scheduled
OpenShift cluster maintenance). To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh integ nonprod
ENABLED=y ./deploy.sh integ nonprod-backup
```

### Update the Prod instances

Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.

```sh
./deploy.sh integ prod-backup
./deploy.sh integ prod
```

To switch to use the backup instance, run the following commands:

```sh
DISABLED=y ./deploy.sh integ prod
ENABLED=y ./deploy.sh integ prod-backup
```
### Note

In deploy.sh, please update "local image_namespace" at line 135 from digital-image-builds to integ-cicd on your local copy.

This is very important as due to the move of Global domains to New Zealand domains, we need to use integ-cicd image stream.