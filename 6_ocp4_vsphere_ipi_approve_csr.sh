#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

oc get csr --no-headers | awk '{print $1}' | xargs oc adm certificate approve

oc get nodes

echo 
echo "Monitor certificates needing approval and verify that nodes become 'Ready' once certificates approved."
echo

