#!/bin/bash

configure-environment() {
  local variant=$1

  BASE_IMAGE_KIND="DockerImage"     
  BASE_IMAGE_NAME="docker-digital-image-builds-local.artifactory.nz.service.anz/jenkins-rhel8/jenkins-rhel8"  
  BASE_IMAGE_TAG="20241120-9fbee37"
  PLUGINS_FILE="plugins.txt"
  EXTRA_PARAMS+=(
    "--set" "defaultSlaveImage.tag=${BASE_IMAGE_TAG}"
  )

  case $variant in
    "dev" | "dev-cs1")
      NAMESPACE="ib-ci-dev"
      if [[ "$variant" == "dev" ]]; then
        CLUSTER="cs2-dev"
        VALUE_FILES+=(
          "../shared/cs2-dev.yaml"
          "common.yaml"
          "dev.yaml"
          "dev-cs2.yaml"
        )
      else
        CLUSTER="cs1-dev"
        VALUE_FILES+=(
          "../shared/cs1-dev.yaml"
          "common.yaml"
          "dev.yaml"
          "dev-cs1.yaml"
        )
      fi

      # seed jobs with the given branch regex
      if [[ -n "$BUILD_BRANCH_REGEX" ]]; then
        echo "BUILD_BRANCH_REGEX=${BUILD_BRANCH_REGEX}"
        if [[ "$BUILD_BRANCH_REGEX" == *"master"* ]]; then
          print-error "Invalid BUILD_BRANCH_REGEX specified, master branch is reserved for the production Jenkins instance"
          return 1
        fi
        if [[ "$BUILD_BRANCH_REGEX" == "PR-.*" ]]; then
          print-error "Invalid BUILD_BRANCH_REGEX specified, PR-.* is reserved for the non-prod Jenkins instance"
          return 1
        fi

        EXTRA_PARAMS+=(
          "--set" "buildBranchRegex=${BUILD_BRANCH_REGEX}"
        )
      fi

      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
      ;;
    "nonprod")
      CLUSTER="cs2-dev"
      NAMESPACE="ib-ci"
      RELEASE_NAME="jenkins"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "nonprod.yaml"
        "nonprod-cs2.yaml"
      )
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
      ;;
    "nonprod-backup")
      CLUSTER="cs1-dev"
      NAMESPACE="ib-ci"
      RELEASE_NAME="jenkins"
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "nonprod.yaml"
        "nonprod-cs1.yaml"
      )
      if [[ "$ENABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=false"
        )
        print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
        print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh ib nonprod'."
        print-warn "Enter to continue or Ctrl-C to abort"
        read -r _
      fi
      ;;
    "prod")
      CLUSTER="cs2-prod"
      NAMESPACE="ib-ci"
      RELEASE_NAME="jenkins"
      VALUE_FILES+=(
        "../shared/cs2-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-credentials.yaml"
        "prod-cs2.yaml"
      )
      if [[ "$DISABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=true"
        )
      fi
      ;;
    "prod-backup")
      CLUSTER="cs1-prod"
      NAMESPACE="ib-ci"
      RELEASE_NAME="jenkins"
      VALUE_FILES+=(
        "../shared/cs1-prod.yaml"
        "common.yaml"
        "prod.yaml"
        "prod-credentials.yaml"
        "prod-cs1.yaml"
      )
      if [[ "$ENABLED" == "y" ]]; then
        EXTRA_PARAMS+=(
          "--set" "JCasC.quietDown.quietDown=false"
        )
        print-warn "WARNING: You are trying to deploy and activate the backup Jenkins instance."
        print-warn "Make sure you have deactivated the main instance first by running 'DISABLED=y ./deploy.sh ib prod'."
        print-warn "Enter to continue or Ctrl-C to abort"
        read -r _
      fi
      ;;
    *)
      print-error "Invalid variant specified. See sites/ib/README.md for list of valid variants"
      return 1
  esac
}
