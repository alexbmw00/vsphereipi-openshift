#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

pushd $CLUSTER/installer
terraform destroy -auto-approve
popd

