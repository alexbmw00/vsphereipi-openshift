#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

openshift-install --dir $CLUSTER create ignition-configs --log-level debug

if [ ! -d /var/www/html ]; then
  echo "WARNING:  /var/www/html does not exist!  Please make sure to install httpd service on this system.  The ignition files will need to be copied to /var/www/html directory manually once HTTPD is installed." >&2
  exit 1
else
  rm -f /var/www/html/${CLUSTER}-*.ign
  cp ${CLUSTER}/bootstrap.ign /var/www/html/${CLUSTER}-bootstrap.ign
  cp ${CLUSTER}/master.ign /var/www/html/${CLUSTER}-master.ign
  cp ${CLUSTER}/worker.ign /var/www/html/${CLUSTER}-worker.ign
  chmod 644 /var/www/html/${CLUSTER}-*.ign
fi

