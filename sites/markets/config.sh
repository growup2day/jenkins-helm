#!/bin/bash

configure-environment() {
  local variant=$1

  NAMESPACE="mkts-tools"
  RELEASE_NAME="jenkins"
   # with Jenkins 2.401.1
  BASE_IMAGE_KIND="DockerImage"
  BASE_IMAGE_NAME="docker-digital-image-builds-local.artifactory.nz.service.anz/jenkins-rhel8/jenkins-rhel8"
  BASE_IMAGE_TAG="20240619-9b4a590"
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
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
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
      if [[ "$ENABLED" == "y" ]]; then
       EXTRA_PARAMS+=(
         "--set" "JCasC.quietDown.quietDown=false"
       )
       print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
       print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh mkts-tools nonprod'."
       print-warn "Enter to continue or Ctrl-C to abort"
       read -r _
      fi
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
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
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
      if [[ "$ENABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=false"
        )
        print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
        print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh mkts-tools prod'."
        print-warn "Enter to continue or Ctrl-C to abort"
        read -r _
      fi
      ;;
    *)
      print-error "Invalid variant specified. See sites/markets/README.md for list of valid variants"
      return 1
  esac
}