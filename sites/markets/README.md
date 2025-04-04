# Markets site

The Markets site is for provisioning Jenkins instances used by Markets NZ teams. The main instances are in the `cs1`
clusters.

The following variants are supported:

| Variant          | Release name | Cluster    | Description                                                                                |
| ---------------- | ------------ | ---------- | ------------------------------------------------------------------------------------------ |
| `nonprod`        | `jenkins`    | `cs1-dev`  | Main non-prod Jenkins instance for running all feature branch and pull-request builds                             |
| `nonprod-backup` | `jenkins`    | `cs2-dev`  | Backup non-prod Jenkins instance for running all feature branch and pull-request builds, in quiet mode by default |
| `prod`           | `jenkins`    | `cs1-prod` | Prod Jenkins instance for running master branch builds                                     |
| `prod-backup`    | `jenkins`    | `cs2-prod` | Backup Prod Jenkins instance for running master branch builds, in quiet mode by default |

All Markets Jenkins instances will be deployed to the `mkts-tools` namespace.

## Build nodes

Some jobs build on the openshift cloud agents configured in this repo, and some require the permanent build node (nz31rmpa001v). If this node disconnects, you will need to log on to this machine and restart the agent process as the service account user. 

To switch to the service account with asu, no valid change numnber is required in nonprod, so we can force the command. e.g.
```
/opt/sysadm/bin/asu -f -u nzmktsjenkinst1dsa -r "working on non prod" -a 12345678
```