#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

# Delete bootstrap VM
govc vm.destroy /${GOVC_DATACENTER}/vm/${CLUSTER}/${BOOTSTRAP_PREFIX}-0

# Delete master VMs
for i in $(seq 1 ${MASTER_COUNT}); do
  COUNT=$(($i - 1))
  govc vm.destroy /${GOVC_DATACENTER}/vm/${CLUSTER}/${MASTER_PREFIX}-${COUNT}
done

# Delete worker VMs
for i in $(seq 1 ${WORKER_COUNT}); do
  COUNT=$(($i - 1))
  govc vm.destroy /${GOVC_DATACENTER}/vm/${CLUSTER}/${WORKER_PREFIX}-${COUNT}
done

govc object.destroy /${GOVC_DATACENTER}/vm/${CLUSTER}
govc pool.destroy   /${GOVC_DATACENTER}/host/${GOVC_CLUSTER}/Resources/${CLUSTER}

