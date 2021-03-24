#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

openshift-install --dir $CLUSTER wait-for install-complete --log-level debug

