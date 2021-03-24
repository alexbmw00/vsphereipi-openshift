#!/usr/bin/env bash

##### THIS SCRIPT REQUIRES THAT PXE BOOT/TFTP SERVER ALREADY BE CONFIGURED

##### Make sure to have DRS enabled to allow for creation of resource pool for the cluster

source 0_ocp4_vsphere_ipi_init_vars

KERNEL=$(basename `ls /var/lib/tftpboot/rhcos/rhcos-${RHCOS}*-installer-kernel* | sort | tail -1`)
INITRD=$(basename `ls /var/lib/tftpboot/rhcos/rhcos-${RHCOS}*-installer-initramfs* | sort | tail -1`)
IMAGE=$(basename `ls /var/www/html/rhcos-${RHCOS}*-metal* | sort | tail -1`)

# Generate PXE boot file
cat >default <<EOF
# Explicitly set default label to an unknown value.  Force user to enter a correct one below.
DEFAULT dummy
TIMEOUT 20
PROMPT 0

EOF

APPENDBASE="rd.neednet=1 initrd=rhcos/${INITRD} console=tty0 console=ttyS0 coreos.inst=yes coreos.inst.install_dev=sda coreos.inst.image_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${IMAGE} coreos.no_persist_ip=1"

# Add bootstrap entries to PXE boot file
gen_append_ign_file bootstrap ${BOOTSTRAP_PREFIX}-0 ${BOOTSTRAP_IP}
if [ "$BM_BOOT_STATIC" = "Y" ]; then
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${BOOTSTRAP_PREFIX}-0-append.ign ip=${BOOTSTRAP_IP}::${MACHINE_GW}:${MACHINE_NM}:${BOOTSTRAP_PREFIX}-0.${CLUSTER}.${BASE_DOMAIN}:ens192:none nameserver=${MACHINE_DNS1}"
else
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${BOOTSTRAP_PREFIX}-0-append.ign ip=dhcp"
fi
cat >>default <<EOF
LABEL ${CLUSTER}-${BOOTSTRAP_PREFIX}-0
    KERNEL rhcos/${KERNEL}
    APPEND ${APPENDCONF}
EOF

# Add master entries to PXE boot file
COUNT=0
for i in $(echo $MASTER_IPS | tr -d '",'); do
gen_append_ign_file master ${MASTER_PREFIX}-${COUNT} ${i}
if [ "$BM_BOOT_STATIC" = "Y" ]; then
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${MASTER_PREFIX}-${COUNT}-append.ign ip=${i}::${MACHINE_GW}:${MACHINE_NM}:${MASTER_PREFIX}-${COUNT}.${CLUSTER}.${BASE_DOMAIN}:ens192:none nameserver=${MACHINE_DNS1}"
else
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${MASTER_PREFIX}-${COUNT}-append.ign ip=dhcp"
fi
cat >>default <<EOF
LABEL ${CLUSTER}-${MASTER_PREFIX}-${COUNT}
    KERNEL rhcos/${KERNEL}
    APPEND ${APPENDCONF}
EOF
COUNT=$(($COUNT + 1))
done

# Add worker entries to PXE boot file
COUNT=0
for i in $(echo $WORKER_IPS | tr -d '",'); do
gen_append_ign_file worker ${WORKER_PREFIX}-${COUNT} ${i}
if [ "$BM_BOOT_STATIC" = "Y" ]; then
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${WORKER_PREFIX}-${COUNT}-append.ign ip=${i}::${MACHINE_GW}:${MACHINE_NM}:${WORKER_PREFIX}-${COUNT}.${CLUSTER}.${BASE_DOMAIN}:ens192:none nameserver=${MACHINE_DNS1}"
else
  APPENDCONF=${APPENDBASE}" coreos.inst.ignition_url=http://${HOST_SHORT}.${BASE_DOMAIN}/${CLUSTER}-${WORKER_PREFIX}-${COUNT}-append.ign ip=dhcp"
fi
cat >>default <<EOF
LABEL ${CLUSTER}-${WORKER_PREFIX}-${COUNT}
    KERNEL rhcos/${KERNEL}
    APPEND ${APPENDCONF}
EOF
COUNT=$(($COUNT + 1))
done

# Copy generated PXE boot file to /var/lib/tftpboot/pxelinux.cfg
if [ ! -d /var/lib/tftpboot/pxelinux.cfg ]; then
  echo "WARNING:  /var/lib/tftpboot/pxelinux.cfg does not exist!  Please make sure to create the directory on this system and copy the generated default pxe boot file to it." >&2
  exit 1
else
  mv /var/lib/tftpboot/pxelinux.cfg/default /var/lib/tftpboot/pxelinux.cfg/default.bak
  cp default /var/lib/tftpboot/pxelinux.cfg
  rm -f default
fi

# Create resource pool and folder for cluster
govc pool.create   /${GOVC_DATACENTER}/host/${GOVC_CLUSTER}/Resources/${CLUSTER}
govc folder.create /${GOVC_DATACENTER}/vm/${CLUSTER}

# Create bootstrap VM
govc vm.create -m=${BOOTSTRAP_MEM} -c=${BOOTSTRAP_CPU} -g=coreos64Guest -net.adapter=vmxnet3 -net=${GOVC_NETWORK} -disk.controller=pvscsi -disk=${BOOTSTRAP_DISK}GB -on=false -pool=/${GOVC_DATACENTER}/host/${GOVC_CLUSTER}/Resources/${CLUSTER} -folder=/${GOVC_DATACENTER}/vm/${CLUSTER} ${BOOTSTRAP_PREFIX}-0
govc vm.change -e="disk.enableUUID=1" -vm="/${GOVC_DATACENTER}/vm/${CLUSTER}/${BOOTSTRAP_PREFIX}-0"
govc vm.power -on=true /${GOVC_DATACENTER}/vm/${CLUSTER}/${BOOTSTRAP_PREFIX}-0

# Create master VMs
for i in $(seq 1 ${MASTER_COUNT}); do
  COUNT=$(($i - 1))
  govc vm.create -m=${MASTER_MEM} -c=${MASTER_CPU} -g=coreos64Guest -net.adapter=vmxnet3 -net=${GOVC_NETWORK} -disk.controller=pvscsi -disk=${MASTER_DISK}GB -on=false -pool=/${GOVC_DATACENTER}/host/${GOVC_CLUSTER}/Resources/${CLUSTER} -folder=/${GOVC_DATACENTER}/vm/${CLUSTER} ${MASTER_PREFIX}-${COUNT}
  govc vm.change -e="disk.enableUUID=1" -vm="/${GOVC_DATACENTER}/vm/${CLUSTER}/${MASTER_PREFIX}-${COUNT}"
  govc vm.power -on=true /${GOVC_DATACENTER}/vm/${CLUSTER}/${MASTER_PREFIX}-${COUNT}
done

# Create worker VMs
for i in $(seq 1 ${WORKER_COUNT}); do
  COUNT=$(($i - 1))
  govc vm.create -m=${WORKER_MEM} -c=${WORKER_CPU} -g=coreos64Guest -net.adapter=vmxnet3 -net=${GOVC_NETWORK} -disk.controller=pvscsi -disk=${WORKER_DISK}GB -on=false -pool=/${GOVC_DATACENTER}/host/${GOVC_CLUSTER}/Resources/${CLUSTER} -folder=/${GOVC_DATACENTER}/vm/${CLUSTER} ${WORKER_PREFIX}-${COUNT}
  govc vm.change -e="disk.enableUUID=1" -vm="/${GOVC_DATACENTER}/vm/${CLUSTER}/${WORKER_PREFIX}-${COUNT}"
  govc vm.power -on=true /${GOVC_DATACENTER}/vm/${CLUSTER}/${WORKER_PREFIX}-${COUNT}
done

echo
echo "Launch the VM console and kick off the pxeboot process on each node"
echo
echo
read -p "Press [Enter] key to continue once all nodes have been pxeboot'ed..."

openshift-install --dir $CLUSTER wait-for bootstrap-complete --log-level debug
if [ $? -ne 0 ]; then
  echo "ERROR:  Bootstrap process failed!  Please investigate bootkube.service log on bootstrap node." >&2
else
  echo "INFO:   Bootstrap process completed successfully!  Destroying bootstrap node..."
  govc vm.destroy /${GOVC_DATACENTER}/vm/${CLUSTER}/${BOOTSTRAP_PREFIX}-0
  echo
  echo "# Delete the bootstrap node DNS record, including its corresponding api and api-int records once the VM has been destroyed."
  echo "# If you are using a named service for DNS, you can set  BOOTSTRAP_DISABLE_DNS="Y" in 0_ocp4_vsphere_ipi_init_vars config file and re-run script"
  echo "# 1_ocp4_vsphere_ipi_optional_update_dns.sh.  This will generate and push a new DNS config which will disable/remove the bootstrap server from DNS."
  echo
fi

