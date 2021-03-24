# vsphereipi-openshift

Before executing:
- Copy 0_ocp4_vsphere_ipi_init_vars.template as 0_ocp4_vsphere_ipi_init_vars and adapt the configuration to your environment.

To install:
- Run each shell script in order.
- There are some "optional" scripts such as DNS and local registry configuration which are optional steps.
- Normally, steps 1 - 8 would be the only steps needed to fully install a cluster.
- Step 8 will allow you to perform a kubeadmin password reset, if needed.
- Step 9 will destroy a provisioned cluster.

