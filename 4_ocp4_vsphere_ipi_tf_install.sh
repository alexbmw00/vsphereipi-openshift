#!/usr/bin/env bash

##### Make sure to have DRS enabled to allow for creation of resource pool for the cluster

source 0_ocp4_vsphere_ipi_init_vars

pushd $CLUSTER
[ -d installer ] && rm -fr installer
cp -r ../installer .
pushd installer
sed -e "s|\${CLUSTER}|${CLUSTER}|g" terraform.tfvars.template >terraform.tfvars.$$
sed -i -e "s|\${BASE_DOMAIN}|${BASE_DOMAIN}|g" terraform.tfvars.$$
sed -i -e "s|\${GOVC_URL}|${GOVC_URL}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_USERNAME}|${GOVC_USERNAME}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_PASSWORD}|${GOVC_PASSWORD}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_CLUSTER}|${GOVC_CLUSTER}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_DATACENTER}|${GOVC_DATACENTER}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_DATASTORE}|${GOVC_DATASTORE}|" terraform.tfvars.$$
sed -i -e "s|\${RHCOS_TEMPLATE}|${RHCOS_TEMPLATE}|" terraform.tfvars.$$
sed -i -e "s|\${GOVC_NETWORK}|${GOVC_NETWORK}|" terraform.tfvars.$$
sed -i -e "s|\${MACHINE_CIDR}|${MACHINE_CIDR}|" terraform.tfvars.$$
sed -i -e "s|\${MACHINE_GW}|${MACHINE_GW}|" terraform.tfvars.$$
sed -i -e "s|\${MACHINE_DNS1}|${MACHINE_DNS1}|" terraform.tfvars.$$
sed -i -e "s|\${MACHINE_DNS2}|${MACHINE_DNS2}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_COUNT}|${MASTER_COUNT}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_COUNT}|${WORKER_COUNT}|" terraform.tfvars.$$
sed -i -e "s|\${BOOTSTRAP_PREFIX}|${BOOTSTRAP_PREFIX}|" terraform.tfvars.$$
sed -i -e "s|\${BOOTSTRAP_IP}|${BOOTSTRAP_IP}|" terraform.tfvars.$$
sed -i -e "s|\${BOOTSTRAP_CPU}|${BOOTSTRAP_CPU}|" terraform.tfvars.$$
sed -i -e "s|\${BOOTSTRAP_MEM}|${BOOTSTRAP_MEM}|" terraform.tfvars.$$
sed -i -e "s|\${BOOTSTRAP_DISK}|${BOOTSTRAP_DISK}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_PREFIX}|${MASTER_PREFIX}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_IPS}|${MASTER_IPS}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_CPU}|${MASTER_CPU}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_MEM}|${MASTER_MEM}|" terraform.tfvars.$$
sed -i -e "s|\${MASTER_DISK}|${MASTER_DISK}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_PREFIX}|${WORKER_PREFIX}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_IPS}|${WORKER_IPS}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_CPU}|${WORKER_CPU}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_MEM}|${WORKER_MEM}|" terraform.tfvars.$$
sed -i -e "s|\${WORKER_DISK}|${WORKER_DISK}|" terraform.tfvars.$$
sed -i -e "s|\${HOST_SHORT}|${HOST_SHORT}|" terraform.tfvars.$$
awk '/^END_OF_MASTER_IGNITION/{while(getline line<"../master.ign"){print line}} //' terraform.tfvars.$$ >terraform.tfvars.$$.1
awk '/^END_OF_WORKER_IGNITION/{while(getline line<"../worker.ign"){print line}} //' terraform.tfvars.$$.1 >terraform.tfvars
rm -f terraform.tfvars.$$*
rm -f terraform.tfvars.template

terraform init
terraform apply -auto-approve
if [ $? -ne 0 ]; then
  echo "ERROR:  Terraform resource creation step failed!  Please check the terraform output for more details." >&2
else
  openshift-install --dir ../../$CLUSTER wait-for bootstrap-complete --log-level debug
  if [ $? -ne 0 ]; then
    echo "ERROR:  Bootstrap process failed!  Please investigate bootkube.service log on bootstrap node." >&2
  else
    terraform apply -auto-approve -var 'bootstrap_complete=true'
    echo
    echo "# Delete the bootstrap node DNS record, including its corresponding api and api-int records once the VM has been destroyed."
    echo "# If you are using a named service for DNS, you can set  BOOTSTRAP_DISABLE_DNS="Y" in 0_ocp4_vsphere_ipi_init_vars config file and re-run script"
    echo "# 1_ocp4_vsphere_ipi_optional_update_dns.sh.  This will generate and push a new DNS config which will disable/remove the bootstrap server from DNS."
    echo
  fi
fi
popd
popd

