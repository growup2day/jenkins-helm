# Online Store site

The Online Store site is for provisioning Jenkins instances used by the Online Store / Digital Sales team.

There is only a single variant for now, prod instance to be added later:

| Variant   | Release name | Cluster   | Description                                              |
| --------- | ------------ |-----------|----------------------------------------------------------|
| `nonprod` | `jenkins`    | `cs1-dev` | Main non-prod Jenkins instance for Onlinestore and SDP   |
| `nonprod-backup` | `jenkins`    | `cs2-dev` | Backup non-prod Jenkins instance for Onlinestore and SDP |
| `nonprod` | `jenkins`    | `cs1-prod` | Main non-prod Jenkins instance for Onlinestore and SDP in production   |
| `nonprod-backup` | `jenkins`    | `cs2-prod` | Backup non-prod Jenkins instance for Onlinestore and SDP in production |

All Jenkins instances will be deployed to the `ols-tools` namespace.

## Provision

see https://bitbucket.nz.service.anz/projects/DIG/repos/jenkins-helm/browse#deploying for how to login to openshift cluster to deploy the Jenkins instance.

### Update the non-prod instances
Always deploy to both the main and the backup instances, starting from the one that's in quiet down mode and verify that
the changes are applied successfully, before applying to the active instance.
```sh
./deploy.sh onlinestore nonprod-backup
./deploy.sh onlinestore nonprod
./deploy.sh onlinestore prod-backup
./deploy.sh onlinestore prod
```