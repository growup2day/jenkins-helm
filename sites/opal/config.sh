#!/bin/bash

configure-environment() {
  local variant=$1

  NAMESPACE="opal-tools"
  RELEASE_NAME="jenkins"
  BASE_IMAGE_TAG="latest"
  BASE_IMAGE_KIND="DockerImage"
  BASE_IMAGE_NAME="docker-digital-image-builds-local.artifactory.nz.service.anz/jenkins-rhel8/jenkins-rhel8"
  PLUGINS_FILE="plugins.txt"
  case $variant in
    "nonprod")
      CLUSTER="cs1-dev"
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "nonprod.yaml"
        "nonprod-cs1.yaml"
      )
      ;;
    "nonprod-backup")
      CLUSTER="cs2-dev"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "nonprod.yaml"
        "nonprod-cs2.yaml"
      )
      ;;
    "prod")
      CLUSTER="cs1-prod"
      VALUE_FILES+=(
        "../shared/cs1-prod.yaml"
        "common.yaml"
        "credentials-prod.yaml"
        "prod.yaml"
        "prod-cs1.yaml"
      )
      ;;
    "prod-backup")
      CLUSTER="cs2-prod"
      VALUE_FILES+=(
        "../shared/cs2-prod.yaml"
        "common.yaml"
        "credentials-prod.yaml"
        "prod.yaml"
        "prod-cs2.yaml"
      )
      ;;
    *)
      print-error "Invalid variant specified. See sites/opal/README.md for list of valid variants"
      return 1
  esac
}