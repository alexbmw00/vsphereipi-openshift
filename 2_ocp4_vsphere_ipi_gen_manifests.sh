#!/usr/bin/env bash

### THIS STEP WILL CREATE THE MANIFESTS ALLOWING YOU TO CUSTOMIZE ANY RESOURCES PRIOR TO GENERATING THE FINAL IGNITION CONFIG

source 0_ocp4_vsphere_ipi_init_vars

openshift-install --dir $CLUSTER create manifests --log-level debug

