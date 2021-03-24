#!/usr/bin/env bash

# Make sure to verify that the cluster imageregistry has been deployed prior to running this.

# This script patches the imageregistry to use emptyDir (ephemeral) storage in the case of non-production.
# Some form of persistent storage should be used in the case of a production environment.

source 0_ocp4_vsphere_ipi_init_vars

oc patch configs.imageregistry.operator.openshift.io cluster --type merge --patch '{"spec":{"storage":{"emptyDir":{}},"managementState":"Managed"}}'

