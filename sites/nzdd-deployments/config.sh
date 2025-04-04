#!/bin/bash

configure-environment() {
    local variant=$1

    # Image Repo: https://bitbucket.nz.service.anz/projects/NZDD-OPS/repos/rhcr-jenkins
    BASE_IMAGE_NAME="docker-nzdd-virtual.artifactory-staging.nz.service.anz/rhcr/rhel8/jenkins"
    BASE_IMAGE_TAG="v2.440.3-rev.d"
    BASE_IMAGE_KIND="DockerImage"
    IMAGE_NAMESPACE="nzdd-jenkins-dev"

    PLUGINS_FILE="plugins.txt"

    case $variant in
        # Deploy to OpenShift Cluster cs1-prod with the PRODUCTION route
        "cs1-prod")
            CLUSTER="cs1-prod"
            NAMESPACE="nzdd-jenkins-prod"
            RELEASE_NAME="jenkins"
            PROD_IMAGE_NAMESPACE="nzdd-jenkins-prod"
            VALUE_FILES+=(
                "../shared/cs1-prod.yaml"
                "common.yaml"
                "pod-templates.yaml"
                "prod.yaml"
                "prod-credentials.yaml"
                "jobs.yaml"
                "prod-jobs.yaml"
                "cs1-prod.yaml"
            )
        ;;
        # Deploy to OpenShift Cluster cs1-dev with the PRODUCTION route
        "cs1-dev")
            CLUSTER="cs1-dev"
            NAMESPACE="nzdd-jenkins-dev"
            RELEASE_NAME="jenkins"
            VALUE_FILES+=(
                "../shared/cs1-dev.yaml"
                "common.yaml"
                "pod-templates.yaml"
                "nonprod.yaml"
                "nonprod-credentials.yaml"
                "jobs.yaml"
                "nonprod-jobs.yaml"
                "cs1-dev.yaml"
            )
        ;;
        # Deploy to OpenShift Cluster cs1-dev with the TEST route
        "cs1-dev-test")
            CLUSTER="cs1-dev"
            NAMESPACE="nzdd-jenkins-dev"
            RELEASE_NAME="jenkins"
            VALUE_FILES+=(
                "../shared/cs1-dev.yaml"
                "common.yaml"
                "pod-templates.yaml"
                "nonprod.yaml"
                "nonprod-credentials.yaml"
                "jobs.yaml"
                "nonprod-jobs.yaml"
                "cs1-dev-test.yaml"
            )
        ;;
        # Deploy to OpenShift Cluster cs2-prod with the TEST route
        "cs2-prod-test")
            CLUSTER="cs2-prod"
            NAMESPACE="nzdd-jenkins-prod"
            RELEASE_NAME="jenkins"
            PROD_IMAGE_NAMESPACE="nzdd-jenkins-prod"
            VALUE_FILES+=(
                "../shared/cs2-prod.yaml"
                "common.yaml"
                "pod-templates.yaml"
                "prod.yaml"
                "prod-credentials.yaml"
                "jobs.yaml"
                "prod-jobs.yaml"
                "cs2-prod-test.yaml"
            )
        ;;
        # Deploy to OpenShift Cluster cs2-dev with the TEST route
        "cs2-dev-test")
            CLUSTER="cs2-dev"
            NAMESPACE="nzdd-jenkins-dev"
            RELEASE_NAME="jenkins"
            VALUE_FILES+=(
                "../shared/cs2-dev.yaml"
                "common.yaml"
                "pod-templates.yaml"
                "nonprod.yaml"
                "nonprod-credentials.yaml"
                "jobs.yaml"
                "nonprod-jobs.yaml"
                "cs2-dev-test.yaml"
            )
        ;;
    *)

    print-error "Invalid variant specified. See sites/sample/README.md for list of valid variants"
    return 1
esac
}