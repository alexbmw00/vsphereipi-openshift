#!/usr/bin/env bash

### THIS STEP IS ONLY REQUIRED IF YOU PLAN TO PERFORM A DISCONNECTED INSTALLATION ###

source 0_ocp4_vsphere_ipi_init_vars

echo "${PULL_SECRET}" | jq ".auths += {\"${LOCAL_REG}\": {\"auth\": \"${SECRET}\",\"email\": \"noemail@localhost\"}}" > ${LOCAL_SECRET_JSON}

oc adm release mirror -a ${LOCAL_SECRET_JSON} \
--from=quay.io/${UPSTREAM_REPO}/${RELEASE_NAME}:${OCP_RELEASE} \
--to-release-image=${LOCAL_REG}/${LOCAL_REPO}:${OCP_RELEASE} \
--to=${LOCAL_REG}/${LOCAL_REPO}

rm -f ${LOCAL_SECRET_JSON}

