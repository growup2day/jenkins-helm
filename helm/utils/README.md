# Util scripts

Scripts in this folder gets mounted to Jenkins master pod at `/var/lib/jenkins-utils`.

Currently the one script `reload-config-on-change.py` is used by `deploy.sh` to trigger JCasC reload after release.
