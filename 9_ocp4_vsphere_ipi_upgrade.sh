#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

if [ "$DISCONNECTED_INSTALL" = "Y" ]; then
  oc adm upgrade --to-image=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE} --allow-explicit-upgrade --force
else
  if [ "$RELEASE" = "latest" ]; then
    oc adm upgrade --to-latest=true
  else
    oc adm upgrade --to=${RELEASE}
  fi
fi

