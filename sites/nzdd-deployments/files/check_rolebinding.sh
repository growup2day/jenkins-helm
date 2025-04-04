#!/bin/bash -e

# Verifies existence and specific role for a RoleBinding in a given Namespace.

# <OC_PROJECT>: The OpenShift project (namespace) where the RoleBinding is located.
# <ROLE_BINDING_NAME>: The name of the RoleBinding you want to check.
# <ROLE_REF>: The specific role that the RoleBinding should reference.

# Usage:
# ./check_rolebinding.sh <OC_PROJECT> <ROLE_BINDING_NAME> <ROLE_REF>
OC_PROJECT=$1
ROLE_BINDING_NAME=$2
ROLE_REF=$3

role_name=$(oc get rolebinding -n $OC_PROJECT -o json | jq -r ".items[] | select(.metadata.name == \"$ROLE_BINDING_NAME\") | .roleRef.name")

if [ "$ROLE_REF" != "$role_name" ]; then
    echo "Error: The role reference (ROLE_REF: $ROLE_REF) does not match the expected role (role: $role_name) for the Namespace ($OC_PROJECT)."
    exit 1
fi