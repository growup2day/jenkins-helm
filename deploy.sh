#!/bin/bash -e

# causes errors within functions to bubble up
set -E
# prevents errors in a pipeline from being masked
set -o pipefail
# Uncomment to trace all commands
# set -o xtrace

# trap
trap "failure" ERR

temp_dir=tmp

usage() {
  echo "Usage: $0 <site> <variant> [options...]"
  echo ""
  echo "options:"
  echo " -d, --dry-run          Dry run, will output the resulting YAML instead of performing upgrade"
  echo " -h, --help             This help text"
  echo " -r, --release-name     Helm release name, only if not define in site config"
  echo " -s, --skip-auto-reload Skip auto-reload of JCasC after release"
}

COLOUR_RED='\033[0;31m'
COLOUR_YELLOW='\033[0;33m'
COLOUR_GREEN='\033[0;32m'
COLOUR_GRAY='\033[0;90m'
COLOUR_NONE='\033[0m'

# Set this as the default SHA tool to use on Linux. We later change this when running on MacOS.
SHA_TOOL=sha256sum

print-warn() {
  printf "${COLOUR_YELLOW}%s${COLOUR_NONE}\n" "$1" 1>&2
}
print-error() {
  printf "${COLOUR_RED}%s${COLOUR_NONE}\n" "$1" 1>&2
}
print-success() {
  printf "${COLOUR_GREEN}%s${COLOUR_NONE}\n" "$1"
}
failure() {
  print-error "Deployment failed."
  print-error "Last executed command: $BASH_COMMAND"
}


# Default implementation that always errors, to be overridden by site specific config.sh
configure-environment() {
  local variant=$1
  # The overriding function needs to set the following variables for the given variant
  # - CLUSTER                      Kubernetes cluster name, see function use-cluster for valid values
  # - NAMESPACE                    Kubernetes namespace to deploy the Jenkins instance into
  # - VALUE_FILES                  String array containing one or more value file paths (relative to the individual site folder) set it like this VALUE_FILES+=("values.yaml")
  # - BASE_IMAGE_TAG               Tag of the openshift/jenkins-ocp-anz image to base the image from
  # - PLUGINS_FILE                 Optional - Path to the Jenkins plugins.txt file (relative to the individual site folder) for the plugins to be installed
  # - EXTRA_PARAMS                 Optional - String array containing any extra parameters to be passed to the helm upgrade command
  # - RELEASE_NAME                 Optional - When set, use the specified name instead of the command line option.
  # - IMAGE_NAMESPACE              Optional - Set the namespace to output the image to. Defaults to digital-image-builds.
  # - PROD_IMAGE_NAMESPACE         Optional - Only required to be set when promoting your image to prod and the name of your prod namespace is different to your non-prod namespace.
  print-error "Please define configure-environment() in your config.sh"
  return 1
}


# When running on MacOS, sha256sum is not available by default, so use shasum instead.
set-sha-tool() {
  if [[ "$(uname)" == "Darwin" ]]; then
    SHA_TOOL=shasum
  fi
}


# Setup to use the specified OpenShift cluster
use-cluster() {
  local cluster=$1
  case $cluster in
    "cs1-dev")
      local context_server="api-cs1-dev-nz-service-test:6443"
      ;;
    "cs2-dev")
      local context_server="api-cs2-dev-nz-service-test:6443"
      ;;
    "cs1-prod")
      local context_server="api-cs1-nz-service-anz:6443"
      local nonprod_context_server="api-cs1-dev-nz-service-test:6443"
      IS_PRODUCTION="yes"
      NONPROD_REGISTRY="default-route-openshift-image-registry.apps.cs1-dev.nz.service.test"
      PROD_REGISTRY="default-route-openshift-image-registry.apps.cs1.nz.service.anz"
      ;;
    "cs2-prod")
      local context_server="api-cs2-nz-service-anz:6443"
      local nonprod_context_server="api-cs2-dev-nz-service-test:6443"
      IS_PRODUCTION="yes"
      NONPROD_REGISTRY="default-route-openshift-image-registry.apps.cs2-dev.nz.service.test"
      PROD_REGISTRY="default-route-openshift-image-registry.apps.cs2.nz.service.anz"
      ;;
    # remove the next 2 options when OpenShift 3 clusters are retired
    "ocp3-dev")
      local context_server="caas-master-nz-service-test:8443"
      ;;
    "ocp3-prod")
      local context_server="caas-master-nzlb-service-anz:8443"
      local nonprod_context_server="caas-master-nz-service-test:8443"
      IS_PRODUCTION="yes"
      NONPROD_REGISTRY="docker-registry-default.caas.nz.service.test"
      PROD_REGISTRY="docker-registry-default.caas.nz.service.anz"
      ;;
    *)
      print-error "Invalid cluster in site config"
      return 1
  esac

  echo "Setting OC context for $context_server"
  KUBE_CONTEXT=$(oc config get-contexts -o name | grep "$context_server" | head -1) || {
    print-error "Could not find Kubernetes context for $context_server, please log in to the cluster before executing this script."
    return 1
  }
  # switch to target namespace in case the namespace-specific kube context doesn't yet exist
  oc --context "$KUBE_CONTEXT" project "$NAMESPACE"
  KUBE_CONTEXT=$(oc config get-contexts -o name | grep "$NAMESPACE/$context_server" | head -1)
  OC_CMD="oc --context $KUBE_CONTEXT"

  if [[ "$IS_PRODUCTION" == "yes" ]]; then
    echo "Setting OC context for $nonprod_context_server"
    NONPROD_KUBE_CONTEXT=$(oc config get-contexts -o name | grep "$nonprod_context_server" | head -1) || {
      print-error "Could not find Kubernetes context for $nonprod_context_server, please log in to the cluster before executing this script."
      return 1
    }

    # switch to "digital-image-builds" namespace in case the namespace-specific kube context doesn't yet exist
    oc --context "$NONPROD_KUBE_CONTEXT" project "digital-image-builds"
    NONPROD_KUBE_CONTEXT=$(oc config get-contexts -o name | grep "digital-image-builds/$nonprod_context_server" | head -1)
    NONPROD_OC_CMD="oc --context $NONPROD_KUBE_CONTEXT"
  fi
}

# Build or migrate image for the specifies site
# performs migration if IS_PRODUCTION=yes, otherwise performs build
build-or-migration-image() {
  local site=$1
  local base_image_tag=$2
  local plugins_file=$3
  local image_rebuild=false

  local image_namespace="${IMAGE_NAMESPACE:-digital-image-builds}"
  local target_image_namespace="${PROD_IMAGE_NAMESPACE:-$image_namespace}"
  local image_name=jenkins-helm
  local base_image_kind="${BASE_IMAGE_KIND:-ImageStreamTag}"
  local base_image_name="${BASE_IMAGE_NAME:-jenkins-ocp-anz}"

  if [[ -z "$base_image_tag" ]]; then
      print-error "BASE_IMAGE_TAG not defined in site config"
      return 1
  fi

  if [[ -z "$plugins_file" ]]; then
    # no additional plugins required
    IMAGE_TAG=$base_image_tag
    local start_build_param=
  else
    local plugins_path="sites/${site}/${plugins_file}"
    if [[ -f "$plugins_path" ]]; then
      local plugins_signature

      # Copy plugin file to tmp folder
      # Ignores empty lines and comments, then sorted to avoid unecessary builds
      local tmp_plugins_file="$temp_dir/plugins.txt"
      grep -v '^$' "$plugins_path" | grep -v '^\#' | LC_ALL=C sort > "$tmp_plugins_file"

      # Generate SHA of the plugins.txt content for unique image tag
      plugins_signature=$($SHA_TOOL "$tmp_plugins_file" | awk '{print $1;}')

      IMAGE_TAG="${base_image_tag}-${plugins_signature}"
      local start_build_param="--from-file=${tmp_plugins_file}"
    else
      print-error "Plugins file ($plugins_path) specified by site config is not found"
      return 1
    fi
  fi

  if [[ $base_image_kind == "DockerImage" ]]; then
    local base_image_namespace="${BASE_IMAGE_NAMESPACE:-}"
    local base_image_digest="$(skopeo inspect docker://${base_image_name}:${base_image_tag} | jq '.Digest')"
  else
     local base_image_namespace="${BASE_IMAGE_NAMESPACE:-openshift}"
  fi

  # Check if the image tag exists in the target namespace
  if ! $OC_CMD -n "$target_image_namespace" describe "istag/$image_name:$IMAGE_TAG" > /dev/null
  then
    echo "Image not found, setting image_rebuild to 'true'"
    image_rebuild=true
  else
    echo """
      Image found.
      Checking if the current base_image_digest matches the latest image digest.
    """
    local current_digest=$($OC_CMD -n "$target_image_namespace" get "istag/$image_name:$IMAGE_TAG" -ojsonpath='{.image.dockerImageMetadata.Config.Labels.nz\.co\.anz\.base_image_digest}')
    echo "The latest source image digest:     ${base_image_digest}"
    echo "The current used base image digest: ${current_digest}"
    if [[ $base_image_kind == "DockerImage" ]] && [[ "${base_image_digest}" != "${current_digest}" ]]
    then
      echo """
        The current image digest ($current_digest) doesn't match the latest base image($base_image_digest).
        Setting image_rebuild to 'true'
      """
      image_rebuild=true
    else
      print-success "The current image digest matches the latest for the chosen tag."
    fi
  fi

  if [ $image_rebuild == true ]
  then

    if [[ "$IS_PRODUCTION" == "yes" ]]; then
      echo "================================================================================"
      echo "About to promote the $image_namespace/$image_name:$IMAGE_TAG image from non-prod cluster to prod cluster"
      echo "Enter to continue or Ctrl-C to abort"
      read -r _

      local nonprod_token
      nonprod_token=$($NONPROD_OC_CMD whoami -t)
      local prod_token
      prod_token=$($OC_CMD whoami -t)

      skopeo copy \
        --src-creds "user:${nonprod_token}" \
        --dest-creds "user:${prod_token}" \
        "docker://${NONPROD_REGISTRY}/${image_namespace}/${image_name}:${IMAGE_TAG}" \
        "docker://${PROD_REGISTRY}/${target_image_namespace}/${image_name}:${IMAGE_TAG}"

      print-success "Image copied successfully"
    else
      echo "================================================================================"
      echo "About to create the $image_namespace/$image_name:$IMAGE_TAG image"
      echo "Enter to continue or Ctrl-C to abort"
      read -r _

      # create build without actually running one
      local TEMP_IMAGE_TAG
      TEMP_IMAGE_TAG="temp-$RANDOM"
      $OC_CMD process -f jenkins-build.yaml -n "$image_namespace" -o yaml \
        BASE_IMAGE_TAG="$base_image_tag" OUTPUT_IMAGE_TAG="$TEMP_IMAGE_TAG" \
        BASE_IMAGE_KIND="$base_image_kind" BASE_IMAGE_NAME="$base_image_name" \
        BASE_IMAGE_NAMESPACE="$base_image_namespace" BASE_IMAGE_DIGEST="$base_image_digest" \
        | $OC_CMD apply -n "$image_namespace" -f -
      # starting build and watching it complete
      printf "$COLOUR_GRAY"
      $OC_CMD start-build -n "$image_namespace" -w -F bc/$image_name $start_build_param
      printf "$COLOUR_NONE"
      # The successfully build should output the image to the temporary random tag.
      # Now copy image from temp tag to the final tag that the running pod would reference.
      # This additional step is introduced so that if a manual build gets triggered from OpenShift UI by mistake, it
      # would not overwrite the in-use image with one that doesn't contain any plugins at all.
      $OC_CMD tag -n "$image_namespace" "${image_name}:${TEMP_IMAGE_TAG}" "${image_name}:${IMAGE_TAG}"
      $OC_CMD tag -n "$image_namespace" -d "${image_name}:${TEMP_IMAGE_TAG}"
      $OC_CMD get is/${image_name} -n "$image_namespace"

      print-success "Image built successfully"
    fi
  else
    print-success "Image $target_image_namespace/jenkins-helm:$IMAGE_TAG already exists. Skipping build/migration."
  fi
}

main() {
  local POSITIONAL=()
  while [[ $# -gt 0 ]]; do
    key="$1"

    case $key in
      -h|--help)
        usage
        return 0
        ;;
      -r|--release-name)
        local release_name="$2"
        shift # past argument
        shift # past value
        ;;
      -s|--skip-auto-reload)
        local skip_auto_reload="yes"
        shift # past argument
        ;;
      -d|--dry-run)
        local dry_run="yes"
        shift # past argument
        ;;
      *) # unknown option
        POSITIONAL+=("$1") # save it in an array for later
        shift # past argument
        ;;
    esac
  done
  set -- "${POSITIONAL[@]}" # restore positional parameters

  local site=${1}
  local variant=${2}

  if [ $# -lt 2 ]
  then
    print-error "Too few arguments"
    usage
    return 1
  fi

  local site_config="sites/${site}/config.sh"
  if [[ -f "$site_config" ]]; then
    # shellcheck source=sites/sample/config.sh
    source "${site_config}"
  else
    local sites
    sites=$(find . -name config.sh | sed -E 's/\.\/sites\/(.*)\/config\.sh/\1/' | paste -sd ", " -)
    print-error "Invalid site ${site}, valid values are ${sites}"
    usage
    return 1
  fi

  rm -rf $temp_dir
  mkdir $temp_dir

  VALUE_FILES=()
  EXTRA_PARAMS=()
  configure-environment "$variant"

  # site config provided RELEASE_NAME take precedence over bash argument
  if [[ -z "$RELEASE_NAME" ]]; then
    if [[ -z "$release_name" ]]; then
      print-error "--release-name not defined and there is none provided by the site config"
      usage
      return 1
    fi
  else
    release_name="$RELEASE_NAME"
  fi

  set-sha-tool
  use-cluster "$CLUSTER"
  build-or-migration-image "$site" "$BASE_IMAGE_TAG" "$PLUGINS_FILE"

  local value_files_param=()
  for f in "${VALUE_FILES[@]}"; do
    value_files_param+=("-f" "./sites/${site}/${f}")
  done

  if [[ "$IS_PRODUCTION" == "yes" ]]; then
    local change_request_number
    echo "================================================================================"
    print-warn "This is a production deployment, please provide the change request number (or Ctrl-C to abort):"
    read -r change_request_number
    EXTRA_PARAMS+=(
      "--description" "Change Request: ${change_request_number}"
    )
  fi

  echo "================================================================================"
  echo "Deploying to ${NAMESPACE}/${release_name}"
  echo "Using context: ${KUBE_CONTEXT}"
  echo "Image tag: ${IMAGE_TAG}"
  echo "Value files: ${value_files_param[*]}"
  echo "Extra params: ${EXTRA_PARAMS[*]}"
  echo "Enter to continue or Ctrl-C to abort"
  read -r _

  helm package ./helm/ \
    --app-version "${IMAGE_TAG}" \
    -d $temp_dir/

  if [[ "$dry_run" == "yes" ]]; then
    EXTRA_PARAMS+=("--dry-run")
    skip_auto_reload="yes"
  fi

  local observedGenerationBeforeUpgrade
  observedGenerationBeforeUpgrade=$($OC_CMD -n "$image_namespace" get statefulset -l release-name="${release_name}" -o jsonpath='{.items[*].status.observedGeneration}')

  helm upgrade "${release_name}" \
    ./$temp_dir/jenkins*.tgz \
    --install \
    --kube-context "${KUBE_CONTEXT}" \
    -n ${NAMESPACE} \
    "${value_files_param[@]}" \
    "${EXTRA_PARAMS[@]}" \
    --wait

  local observedGenerationAfterUpgrade
  observedGenerationAfterUpgrade=$($OC_CMD -n "$image_namespace" get statefulset -l release-name="${release_name}" -o jsonpath='{.items[*].status.observedGeneration}')

  if [[ "$observedGenerationAfterUpgrade" == "$observedGenerationBeforeUpgrade" ]]; then
    print-success "Jenkins updated with the latest changes without restart."
  else
    print-success "Jenkins updated with the latest changes. Jenkins master was restarted."
  fi

  # only trigger reload when there was no rollout (i.e. the pod did not restart)
  if [[ "$skip_auto_reload" != "yes" && "$observedGenerationAfterUpgrade" == "$observedGenerationBeforeUpgrade" ]]; then
    echo "Triggering JCasC reload when the new config is updated in the pod, this can take up to 90 seconds."
    local podname
    podname=$($OC_CMD get pod -n ${NAMESPACE} -l release-name="${release_name}" -o name)

    $OC_CMD exec "$podname" -- python3 /var/lib/jenkins-utils/reload-config-on-change.py
  fi

  rm -rf $temp_dir

  # switch back to the deploy target namespace
  oc --context $KUBE_CONTEXT project $NAMESPACE

  print-success "Deployment completed"
}

main "$@"