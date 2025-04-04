#!/bin/bash

configure-environment() {
  local variant=$1

  BASE_IMAGE_TAG="v4.9.1-1"
  PLUGINS_FILE="plugins.txt"
  case $variant in
    "nonprod")
      CLUSTER="cs1-dev"
      NAMESPACE="ints-tools"
      RELEASE_NAME="jenkinscd"
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
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
      NAMESPACE="ints-tools"
      RELEASE_NAME="jenkinscd"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "nonprod.yaml"
        "nonprod-cs2.yaml"
      )
      if [[ "$ENABLED" == "y" ]]; then
       EXTRA_PARAMS+=(
         "--set" "JCasC.quietDown.quietDown=false"
       )
       print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
       print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh integration-services nonprod'."
       print-warn "Enter to continue or Ctrl-C to abort"
       read -r _
      fi
      ;;
    "prod")
      CLUSTER="cs1-prod"
      NAMESPACE="ints-tools"
      RELEASE_NAME="jenkinscd"
      VALUE_FILES+=(
        "../shared/cs1-prod.yaml"
        "common.yaml"
        "prod-credentials.yaml"
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
      NAMESPACE="ints-tools"
      RELEASE_NAME="jenkinscd"
      VALUE_FILES+=(
        "../shared/cs2-prod.yaml"
        "common.yaml"
        "prod-credentials.yaml"
        "prod.yaml"
        "prod-cs2.yaml"
      )
      if [[ "$ENABLED" == "y" ]]; then
       EXTRA_PARAMS+=(
         "--set" "JCasC.quietDown.quietDown=false"
       )
       print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
       print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh integration-services prod'."
       print-warn "Enter to continue or Ctrl-C to abort"
       read -r _
      fi
      ;;
    *)
      print-error "Invalid variant specified. See sites/integration-services/README.md for list of valid variants"
      return 1
  esac
}
