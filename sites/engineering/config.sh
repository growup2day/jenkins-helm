#!/bin/bash

configure-environment() {
  local variant=$1

  CLUSTER="cs1-dev"
  NAMESPACE="engineering"
  RELEASE_NAME="jenkins"
  BASE_IMAGE_TAG="v4.9.1-1" # with Jenkins 2.319.2
  PLUGINS_FILE="plugins.txt"
  case $variant in
    "nonprod")
      VALUE_FILES+=(
        "../shared/cs1-dev.yaml"
        "nonprod-cs1.yaml"
      )
      ;;
    *)
      print-error "Invalid variant specified. See sites/engineering/README.md for list of valid variants"
      return 1
  esac
}