#!/bin/bash

configure-environment() {
  local variant=$1

  BASE_IMAGE_KIND="DockerImage"
  BASE_IMAGE_NAME="docker-digital-image-builds-local.artifactory.nz.service.anz/jenkins-rhel8/jenkins-rhel8"
  BASE_IMAGE_TAG="20240926-d660572"

  PLUGINS_FILE="plugins.txt"

      if [[ "$variant" == "personal" ]]; then
        NAMESPACE="gomoney-jenkins-dev"
        CLUSTER="cs1-dev"
        VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "dev.yaml"
        )
      elif [[ "$variant" == "dev" ]]; then
        NAMESPACE="gomoney-jenkins-dev"
        CLUSTER="cs1-dev"
        RELEASE_NAME="jenkins"
        VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "dev.yaml"
        )
      elif [[ "$variant" == "nonprod" ]]; then
        NAMESPACE="gomoney-ci"
        CLUSTER="cs2-dev"
        RELEASE_NAME="jenkins"
        VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "nonprod.yaml"
        "nonprod-cs2.yaml"
        )
        if [[ "$DISABLED" == "y" ]]; then
          EXTRA_PARAMS+=(
            "--set" "JCasC.quietDown.quietDown=true"
          )
        fi
      elif [[ "$variant" == "nonprod-backup" ]]; then
        NAMESPACE="gomoney-ci"
        CLUSTER="cs1-dev"
        RELEASE_NAME="jenkins"
        VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "credentials-nonprod.yaml"
        "nonprod.yaml"
        "nonprod-cs1.yaml"
        )

        if [[ "$ENABLED" == "y" ]]; then
          EXTRA_PARAMS+=(
            "--set" "JCasC.quietDown.quietDown=false"
          )
          print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
          print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh gomoney nonprod'."
          print-warn "Enter to continue or Ctrl-C to abort"
          read -r _
        fi
      elif [[ "$variant" == "prod" ]]; then
        NAMESPACE="gomoney-ci"
        CLUSTER="cs2-prod"
        RELEASE_NAME="jenkins"
        VALUE_FILES+=(
         "../shared/cs2-prod.yaml"
        "common.yaml"
        "credentials-prod.yaml"
        "prod.yaml"
        "prod-cs2.yaml"
        )

        if [[ "$DISABLED" == "y" ]]; then
          EXTRA_PARAMS+=(
            "--set" "JCasC.quietDown.quietDown=true"
          )
        fi
      elif [[ "$variant" == "prod-backup" ]]; then
        NAMESPACE="gomoney-ci"
        CLUSTER="cs1-prod"
        RELEASE_NAME="jenkins"
        VALUE_FILES+=(
         "../shared/cs1-prod.yaml"
         "common.yaml"
        "credentials-prod.yaml"
         "prod.yaml"
         "prod-cs1.yaml"
        )

        if [[ "$ENABLED" == "y" ]]; then
          EXTRA_PARAMS+=(
            "--set" "JCasC.quietDown.quietDown=false"
          )
          print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
          print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh gomoney prod'."
          print-warn "Enter to continue or Ctrl-C to abort"
          read -r _
        fi
      else
          print-error "Invalid variant specified. See sites/gomoney/README.md for list of valid variants"
          return 1
      fi
}