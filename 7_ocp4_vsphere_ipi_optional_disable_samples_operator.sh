#!/usr/bin/env bash

# Make sure to verify that the cluster imageregistry has been deployed prior to running this.

# This script patches the openshift-cluster-samples-operator configuration to switch it from Managed to Removed since 
# we can't authenticate to Red Hat's remote samples catalog.

source 0_ocp4_vsphere_ipi_init_vars

oc patch configs.samples.operator.openshift.io cluster --type merge --patch '{"spec":{"managementState":"Removed"}}'

