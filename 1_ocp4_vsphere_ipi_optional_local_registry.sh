#!/usr/bin/env bash

### THIS STEP IS ONLY REQUIRED IF YOU PLAN TO PERFORM A DISCONNECTED INSTALLATION ###

source 0_ocp4_vsphere_ipi_init_vars

# Setup podman and httpd for local registry and webserver 
yum -y install podman httpd httpd-tools
firewall-cmd --add-port=5000/tcp --zone=internal --permanent
firewall-cmd --add-port=5000/tcp --zone=public   --permanent
firewall-cmd --add-service=http  --permanent
firewall-cmd --reload

podman stop -a
podman rm -a

rm -fr ${REG_AUTH} ${REG_CERT} ${REG_DATA}
mkdir -p ${REG_AUTH} ${REG_CERT} ${REG_DATA}

pushd opt/registry/certs
openssl req -newkey rsa:4096 -nodes -sha256 -days ${REG_CERT_DAYS} -x509 -subj "${REG_CERT_SUBJ}" -keyout domain.key -out domain.crt
popd

htpasswd -bBc ${REG_AUTH}/htpasswd ${LOCAL_REG_USER} ${LOCAL_REG_PWD}

podman run --name poc-registry -d -p 5000:5000 \
-v ${REG_DATA}:/var/lib/registry:z \
-v ${REG_AUTH}:/auth:z \
-e "REGISTRY_AUTH=htpasswd" \
-e "REGISTRY_AUTH_HTPASSWD_REALM=Registry" \
-e "REGISTRY_HTTP_SECRET=ALongRandomSecretForRegistry" \
-e REGISTRY_AUTH_HTPASSWD_PATH=/auth/htpasswd \
-v ${REG_CERT}:/certs:z \
-e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt \
-e REGISTRY_HTTP_TLS_KEY=/certs/domain.key \
docker.io/library/registry:2

podman stop poc-registry
podman start poc-registry

rm -f /etc/pki/ca-trust/source/anchors/domain.crt
cp ${REG_CERT}/domain.crt /etc/pki/ca-trust/source/anchors/
update-ca-trust extract

curl -u ${LOCAL_REG_USER}:${LOCAL_REG_PWD} https://${LOCAL_REG}/v2/_catalog

