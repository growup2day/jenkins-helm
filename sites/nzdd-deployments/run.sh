#!/bin/bash
# Helper script to run common tasks for the Helm chart. Mainly used at dev time so we don't have to remember the commands.
# This script assumes you're already logged into the correct OpenShift cluster (via oc) and have switched to the correct project.
# If you would like to recieve notifications on macOS, you will need to install terminal-notifier via Homebrew. e.g. brew install terminal-notifier

# Change these to suite.
DEFAULT_DEPLOY_ENV="cs2-dev-test"
APP_NAME="jenkins"
POD_NAME="jenkins-0"
UNITTEST_IMAGE="docker-digital-image-builds-local.artifactory.nz.service.anz/helm-unittest/helm-unittest:3.7.1-0.2.8"

# Do not change these.
ACTION=$1
PARAM="$2"
SCRIPT_ROOT="$(cd "$(dirname "$0")"; pwd -P)" # sites/nzdd-deployments folder
PROJECT_ROOT=$(dirname "$(dirname "$SCRIPT_ROOT")") # jenkins-helm folder
DEPLOY_SITE=$(basename "$SCRIPT_ROOT") # nzdd-deployments folder name

# Use the default deploy environment if the environment variable hasn't been set.
DEPLOY_ENV=${DEPLOY_ENV:-$DEFAULT_DEPLOY_ENV}

# Load in the same environment config that the deploy.sh script uses.
source "$SCRIPT_ROOT/config.sh"
configure-environment $DEPLOY_ENV

# Upload files to the pod using the syntax, "local-file-path|pod-file-path".
UPLOAD_FILES=(
    "$SCRIPT_ROOT/files/build-failure-analyzer.xml|/var/lib/jenkins/build-failure-analyzer.xml"
)

# Concatenate all the value files into a single string.
for file in "${VALUE_FILES[@]}"; do
    value_args+=("-f" "$SCRIPT_ROOT/$file")
done


help() {
    echo
    echo "Available actions:"
    echo " alias            Print out the command to run, to set an alias for this script"
    echo " compile          Compile the Helm chart and display the output"
    echo " deploy           Deploy the Helm chart to OpenShift using the deploy.sh script"
    echo " docker-test      Run the unit tests inside the Docker container"
    echo " docker-tty       Run the Docker container and start an interactive bash shell"
    echo " install-plugins  Install the correct (old) version of the Jenkins Helm plugin"
    echo " mermaidjs        Regenerate MermaidJS diagrams"
    echo " pod-delete       Delete the pod to force it's recreation"
    echo " pod-jwt          Retrieve the pod's latest Vault JWT token"
    echo " pod-kill         Same as pod-delete"
    echo " pod-rsh          Connect a terminal session to the pod."
    echo " pod-watch        Continuosly watch the pod logs. If the pod is deleted, it will continue to watch until the pod comes back online"
    echo " show-route       Show the configured route in the current OpenShift namespace"
    echo " template         Compile the template locally (without connecting to OpenShift)"
    echo " test             Run the unit tests"
    echo " uninstall        Uninstall the Jenkins Helm chart"
    echo " update-snapshot  Update the snapshot of the unit tests"
    echo " upload           Upload files in the UPLOAD_FILES array into the pod"
    echo
}

# Add an alias to make this script easier to run.
alias() {
    echo 'alias run="bash run.sh"'

    if [[ "$(uname)" == "Darwin" ]]; then
        echo 'alias run="bash run.sh"' | pbcopy
        echo "Paste the contents of your clipboard to set the 'run' alias for this terminal session."
    else
        echo "Copy and paste the above line to set the 'run' alias for this terminal session."
    fi
}

# Compile the Helm template output as YAML using OpenShift.
compile() {
    echo "Compiling template using files: ${value_args[@]}"
    helm install "$PROJECT_ROOT/helm" --dry-run --debug --generate-name --set image.tag=demo "${value_args[@]}"
}

# Compile the Helm template output as YAML locally, without using OpenShift.
template() {
    helm template "$PROJECT_ROOT/helm" --set image.tag=demo "${value_args[@]}"
}

# Run the unit tests.
# This needs to be run inside docker-tty
# e.g ./run.sh test statefulset-test.yaml
test() {
    helm unittest "$PROJECT_ROOT/helm" --helm3 --strict -f "$PROJECT_ROOT/helm/unittests/$PARAM"
}

# Update the snapshot of the unit tests.
# This needs to be run inside docker-tty
# e.g ./run.sh update-snapshot statefulset.yaml
update-snapshot() {
    helm unittest "$PROJECT_ROOT/helm" --helm3 --update-snapshot -f "$PROJECT_ROOT/helm/unittests/$PARAM"
}

# Run the Docker container to run the unit tests.
docker-test() {
    docker run -t --rm --entrypoint /apps/test.sh -v $PROJECT_ROOT:/apps $UNITTEST_IMAGE
}

# Run the Docker container and start an interactive bash shell.
docker-tty() {
    docker run -it --rm --entrypoint /bin/bash -v $PROJECT_ROOT:/apps $UNITTEST_IMAGE
}

# Run the Helm chart against OpenShift.
deploy() {
    compile
  
    # if there wasn't an error with the above command then run command
    if [ $? -eq 0 ]; then
        echo "No errors detected, proceeding with deploy"
        CURRENT_DIRECTORY="$PWD"
        
        cd "$PROJECT_ROOT"
        "$PROJECT_ROOT/deploy.sh" $DEPLOY_SITE $DEPLOY_ENV
        hasError=$?

        cd "$CURRENT_DIRECTORY"

        # Post successful deployment activities
        if [ $hasError -eq 0 ]; then
            echo "Performing post deployment activities"
            upload
            notify -title "Jenkins Helm Chart" -message "Deployed successfully" -open "$(show-route)"
            echo "You can access the Jenkins instance on: $(show-route)"
        else
            notify -title "Jenkins Helm Chart" -message "Deployment failed"
        fi
    else
        echo "Error detected. Please check your template files."
        notify -title "Jenkins Helm Chart" -message "Error detected. Please check your template files"
    fi
}

notify() {
    if command -v terminal-notifier > /dev/null 2>&1; then
        terminal-notifier "$@"
    fi
}

# Upload files listed in the UPLOAD_FILES array to the pod.
upload() {
    # Save the original IFS (Internal Field Separator).
    oldIFS=$IFS

    for file in "${UPLOAD_FILES[@]}"; do
        IFS='|' read -r -a files <<< "$file"
        echo "Uploading file: ${files[0]} to: $POD_NAME:${files[1]}"
        oc cp "${files[0]}" $POD_NAME:${files[1]}
    done

    # Restore the original IFS.
    IFS=$oldIFS
}

# Uninstall the Helm chart on OpenShift.
uninstall() {
    helm uninstall $APP_NAME
}

# Install the old version of the Jenkins Helm Unit Test plugin.
install-plugins() {
    echo "Installing Helm UnitTest plugin, docs can be found her: https://github.com/quintush/helm-unittest/blob/master/DOCUMENT.md"
    helm plugin install https://github.com/quintush/helm-unittest
}

# Connect to the OpenShift pod.
pod-rsh() {
    oc rsh $POD_NAME
}

# Print out the pod logs
pod-logs() {
    oc logs pod/$POD_NAME
}

# Delete the Jenkins pod to force a rebuild
pod-delete() {
    oc delete pod/$POD_NAME
    echo "Watching pod come online, press CTRL+C at any time to exit"
    pod-watch
}

# Fetches the JWT token from the pod.
pod-jwt() {
    oc exec pod/$POD_NAME -- cat /var/run/secrets/kubernetes.io/serviceaccount/token ; echo
}

# Continuosly watch the pod logs. If the pod is deleted, it will continue to watch until the pod comes back online
pod-watch() {
    while true; do
        output=$(oc get pod/$POD_NAME | grep Running)
        if [[ $output == *"Running"* ]]; then
            oc logs -f pod/$POD_NAME
        fi
        sleep 1
    done
}

pod-kill() {
    pod-delete
}

show-route() {
    local route=$(oc get route jenkins -o json | jq -r '.spec.host')
    echo "https://${route}"
}

mermaidjs() {
    if command -v mmdc > /dev/null 2>&1; then
        echo "Regenerating MermaidJS diagrams"

        # Find all .mermaid files and process them one by one
        find "$PROJECT_ROOT/sites/nzdd-deployments" -name '*.mermaid' | while read -r file; do
            # Generate the output file name by replacing .mermaid with .png
            output_file="${file%.mermaid}.png"
            
            echo -n "Processing $(basename "$file") -> $(basename "$output_file")..."

            # Run the MermaidJS command with the input and output file names using the a transparent background
            mmdc -i "$file" -o "$output_file" -b transparent
        done
    else
        echo "Please install MermaidJS CLI (mmdc) to generate diagrams: npm install -g @mermaid-js/mermaid-cli"
    fi    
}

# Execute the action if it exists, otherwise print an help message.
if [ -n "$(type -t $ACTION)" ] && [ "$(type -t $ACTION)" = function ]; then
    $ACTION
else
    help
fi