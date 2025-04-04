#!/bin/bash

configure-environment() {
  local variant=$1

  NAMESPACE="ado-ci"

  BASE_IMAGE_KIND="DockerImage"
  BASE_IMAGE_NAME="docker-digital-image-builds-local.artifactory.nz.service.anz/jenkins-rhel8/jenkins-rhel8"
  BASE_IMAGE_TAG="20241210-2f43897"
  PLUGINS_FILE="plugins.txt"
  RELEASE_NAME="ado-jenkins"
  CLUSTER=$variant
  case $variant in
    "cs1-dev")
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "dev.yaml"
        "dev-cs1.yaml"
      )
      ;;
    "cs2-dev")
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "dev.yaml"
        "dev-cs2.yaml"
      )
      ;;
    "cs1-prod")
      VALUE_FILES+=(
        "../shared/cs1-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-cs1.yaml"
      )
      ;;
    "cs2-prod")
      VALUE_FILES+=(
        "../shared/cs2-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-cs2.yaml"
      )
      ;;
    *)
      print-error "Invalid variant specified. Valid variants are cs1-dev, cs2-dev, cs1-prod, and cs2-prod."
      return 1
  esac

}
