#!/bin/bash

configure-environment() {
  local variant=$1

  CLUSTER="cs2-dev"
  NAMESPACE="jenkins-helm"
  BASE_IMAGE_TAG="v4.9.1-1" # with Jenkins 2.319.2
  case $variant in
    "blank")
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "blank.yaml"
      )
      ;;
    "blank-cs1")
      CLUSTER="cs1-dev"
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "blank.yaml"
      )
      ;;
    "blank3")
      CLUSTER="ocp3-dev"
      BASE_IMAGE_TAG="v3.11.524"
      VALUE_FILES+=(
        "../shared/ocp3-dev.yaml"
        "common.yaml"
        "blank.yaml"
      )
      ;;
    "plugins")
      PLUGINS_FILE="plugins.txt"
      RELEASE_NAME="plugins"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "blank.yaml"
      )
      ;;
    "plugins3")
      CLUSTER="ocp3-dev"
      BASE_IMAGE_TAG="v3.11.524"
      PLUGINS_FILE="plugins.txt"
      RELEASE_NAME="plugins"
      VALUE_FILES+=(
        "../shared/ocp3-dev.yaml"
        "common.yaml"
        "blank.yaml"
      )
      ;;
    "jcasc-basic")
      PLUGINS_FILE="plugins.txt"
      RELEASE_NAME="jcasc-basic"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "jcasc-basic.yaml"
      )
      ;;
    "jcasc-default")
      PLUGINS_FILE="plugins.txt"
      RELEASE_NAME="jcasc-default"
      VALUE_FILES+=(
        "../shared/cs2-dev.yaml"
        "common.yaml"
        "jcasc-default.yaml"
      )
      ;;
    "jcasc-default-cs1")
      CLUSTER="cs1-dev"
      PLUGINS_FILE="plugins.txt"
      RELEASE_NAME="jcasc-default"
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "common.yaml"
        "jcasc-default.yaml"
      )
      ;;
    *)
      print-error "Invalid variant specified. See sites/sample/README.md for list of valid variants"
      return 1
  esac
}