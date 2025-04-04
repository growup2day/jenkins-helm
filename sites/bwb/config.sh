#!/bin/bash

configure-environment() {
  local variant=$1

  BASE_IMAGE_TAG="v4.9.1-1"
  PLUGINS_FILE="plugins.txt"
  case $variant in
    "nonprod-ocp3")
      BASE_IMAGE_TAG="v3.11.524-1"
      PLUGINS_FILE="plugins-ocp3.txt"
      CLUSTER="ocp3-dev"
      NAMESPACE="bwb-ci"
      RELEASE_NAME="bwb-jenkins"
      VALUE_FILES+=(
        "../shared/ocp3-dev.yaml"
        "common.yaml"
        "nonprod.yaml"
        "nonprod-ocp3.yaml"
      )
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
      ;;
    "nonprod")
      CLUSTER="cs1-dev"
      NAMESPACE="bwb-tools"
      RELEASE_NAME="bwb-jenkins"
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
      NAMESPACE="bwb-tools"
      RELEASE_NAME="bwb-jenkins"
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
       print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh bwb nonprod'."
       print-warn "Enter to continue or Ctrl-C to abort"
       read -r _
      fi
      ;;
    "prod-ocp3")
      BASE_IMAGE_TAG="v3.11.524-1"
      PLUGINS_FILE="plugins-ocp3.txt"
      CLUSTER="ocp3-prod"
      NAMESPACE="bwb"
      RELEASE_NAME="bwb-jenkins"
      VALUE_FILES+=(
        "../shared/ocp3-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-credentials.yaml"
        "prod-ocp3.yaml"
      )
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
      ;;
    "prod")
      CLUSTER="cs1-prod"
      NAMESPACE="bwb-tools"
      RELEASE_NAME="bwb-jenkins"
      VALUE_FILES+=(
        "../shared/cs1-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-credentials.yaml"
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
      NAMESPACE="bwb-tools"
      RELEASE_NAME="bwb-jenkins"
      VALUE_FILES+=(
        "../shared/cs2-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-credentials.yaml"
        "prod-cs2.yaml"
      )
      if [[ "$ENABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=false"
        )
        print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
        print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh bwb prod'."
        print-warn "Enter to continue or Ctrl-C to abort"
        read -r _
      fi
      ;;
    *)
      print-error "Invalid variant specified. See sites/bwb/README.md for list of valid variants"
      return 1
  esac
}
