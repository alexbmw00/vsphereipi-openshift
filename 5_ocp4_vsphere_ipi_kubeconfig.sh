#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

mkdir -p ~/.kube
cp $CLUSTER/auth/kubeconfig ~/.kube/config.$CLUSTER
cp ~/.kube/config.$CLUSTER ~/.kube/config

oc config view --flatten

