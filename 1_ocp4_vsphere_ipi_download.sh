#!/usr/bin/env bash

source 0_ocp4_vsphere_ipi_init_vars

echo "Downloading release $BUILDNUMBER..."

# Download coreos-ct
curl -s -L -O https://github.com/coreos/container-linux-config-transpiler/releases/download/v0.9.0/ct-v0.9.0-x86_64-unknown-linux-gnu
rm -f /usr/local/bin/ct
cp ct-v0.9.0-x86_64-unknown-linux-gnu /usr/local/bin/ct
chmod +x /usr/local/bin/ct
rm -f ct-v0.9.0-x86_64-unknown-linux-gnu

# Download terraform
curl -s -O https://releases.hashicorp.com/terraform/${TERRAFORM_VER}/${TERRAFORM}
unzip ${TERRAFORM}
rm -f /usr/local/bin/terraform
cp terraform /usr/local/bin
rm -f terraform 
rm -f ${TERRAFORM}

# Download JQ
yum install http://fedora-epel.mirror.iweb.com/7/x86_64/Packages/j/jq-1.6-2.el7.x86_64.rpm \
            http://fedora-epel.mirror.iweb.com/7/x86_64/Packages/o/oniguruma-6.8.2-1.el7.x86_64.rpm

# Download client and installer binaries
[ -f $CLIENT ] || curl -s -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/${CLIENT}
tar xzvf ${CLIENT}
[ -f $INSTALLER ] || curl -s -O https://mirror.openshift.com/pub/openshift-v4/clients/ocp/${RELEASE}/${INSTALLER}
tar xzvf ${INSTALLER}
rm -f /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/openshift-install
cp oc kubectl openshift-install /usr/local/bin
chmod +x /usr/local/bin/oc /usr/local/bin/kubectl /usr/local/bin/openshift-install
rm -f oc kubectl openshift-install README.md
rm -f ${CLIENT} ${INSTALLER}

# Download GOVC
curl -s -L https://github.com/vmware/govmomi/releases/download/${GOVC_VER}/govc_linux_amd64.gz | gunzip > /usr/local/bin/govc
chmod +x /usr/local/bin/govc

# Download RHCOS ova image
for i in $(curl -s --list-only https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RHCOS}/latest/ | egrep "\-vmware" | grep href | sed 's/.*href="//' | sed 's/".*//' | grep '^[a-zA-Z].*'); do
  curl -s -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RHCOS}/latest/$i
  govc vm.destroy /${GOVC_DATACENTER}/vm/${RHCOS_TEMPLATE}
  govc import.ova -name=${RHCOS_TEMPLATE} $i
done
rm -f rhcos-${RHCOS}*

# Download RHCOS bare-metal image
for i in $(curl -s --list-only https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RHCOS}/latest/ | egrep "\-installer|\-metal" | grep href | sed 's/.*href="//' | sed 's/".*//' | grep '^[a-zA-Z].*'); do
  curl -s -O https://mirror.openshift.com/pub/openshift-v4/dependencies/rhcos/${RHCOS}/latest/$i
done
if [ ! -d /var/www/html ]; then
  echo "WARNING:  /var/www/html does not exist!  Please make sure to install httpd service on this system.  The rhcos installer files will need to be copied to /var/www/html directory manually once HTTPD is installed." >&2
  exit 1
else
  rm -f /var/www/html/rhcos-${RHCOS}*
  cp rhcos-${RHCOS}* /var/www/html
  chmod 644 /var/www/html/rhcos-${RHCOS}*
  rm -f rhcos-${RHCOS}*
  if [ ! -d /var/lib/tftpboot ]; then
    echo "WARNING:  /var/lib/tftpboot does not exist!  Please make sure to install tftp-server on this system.  The rhcos installer kernel and image files will need to be copied to /var/lib/tftpboot directory manually once tftp-server is installed." >&2
    exit 1
  else
    mkdir -p /var/lib/tftpboot/rhcos
    rm -f /var/lib/tftpboot/rhcos/rhcos-${RHCOS}*
    cp /var/www/html/rhcos-${RHCOS}*-installer-initramfs*.img /var/www/html/rhcos-${RHCOS}*-installer-kernel* /var/lib/tftpboot/rhcos
  fi
fi

