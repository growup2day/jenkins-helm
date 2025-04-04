# OPAL site

The OPAL site is for provisioning Jenkins instances used by the OPAL team.

| Variant           | Release name | Cluster        | Description                                |
| ----------------- | ------------ | -------------- | ------------------------------------------ |
| `nonprod`         | `jenkins`    | `cs1-dev`      | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup`  | `jenkins`    | `cs2-dev`      | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`            | `jenkins`    | `cs1-prod`     | Main prod Jenkins instance for running master builds                             |
| `prod-backup`     | `jenkins`    | `cs2-prod`     | Backup prod Jenkins instance for running master builds, in quiet mode by default |
All Jenkins instances will be deployed to the `opal-tools` namespace.
