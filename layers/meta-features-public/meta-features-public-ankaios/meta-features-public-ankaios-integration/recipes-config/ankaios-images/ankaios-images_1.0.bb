# Copyright 2026 Elektrobit. All rights reserved.

DESCRIPTION = "Ankaios container images"
LICENSE = "CLOSED"

inherit dpkg-raw

MAINTAINER = "Elektrobit <info@elektrobit.com>"

do_fetch_container_images[network] = "1"
do_fetch_container_images[dirs] = "${WORKDIR}"
addtask fetch_container_images after do_patch before do_install

SRC_URI = " \
    file://postinst \
"

GH_REGISTRY_MIRROR ?= "ghcr.io"

do_fetch_container_images() {
    LOCAL_IMAGE_TARGET_DIR=${WORKDIR}/container-image-storage
    mkdir -p $LOCAL_IMAGE_TARGET_DIR
    skopeo --insecure-policy --override-os linux --override-arch ${DISTRO_ARCH} copy --tmpdir "${WORKDIR}" docker://${GH_REGISTRY_MIRROR}/windsource/ankaios-dashboard:1.0.0 "containers-storage:[overlay@$LOCAL_IMAGE_TARGET_DIR+$LOCAL_IMAGE_TARGET_DIR]ghcr.io/windsource/ankaios-dashboard:1.0.0"
    skopeo --insecure-policy --override-os linux --override-arch ${DISTRO_ARCH} copy --tmpdir "${WORKDIR}" docker://${GH_REGISTRY_MIRROR}/eclipse-kuksa/kuksa-databroker:0.7.0 "containers-storage:[overlay@$LOCAL_IMAGE_TARGET_DIR+$LOCAL_IMAGE_TARGET_DIR]ghcr.io/eclipse-kuksa/kuksa-databroker:0.7.0"
    skopeo --insecure-policy --override-os linux --override-arch ${DISTRO_ARCH} copy --tmpdir "${WORKDIR}" docker://${GH_REGISTRY_MIRROR}/eclipse-ankaios/speed-provider:0.1.3 "containers-storage:[overlay@$LOCAL_IMAGE_TARGET_DIR+$LOCAL_IMAGE_TARGET_DIR]ghcr.io/eclipse-ankaios/speed-provider:0.1.3"
    skopeo --insecure-policy --override-os linux --override-arch ${DISTRO_ARCH} copy --tmpdir "${WORKDIR}" docker://${GH_REGISTRY_MIRROR}/eclipse-ankaios/speed-consumer:0.1.2 "containers-storage:[overlay@$LOCAL_IMAGE_TARGET_DIR+$LOCAL_IMAGE_TARGET_DIR]ghcr.io/eclipse-ankaios/speed-consumer:0.1.2"
    sudo tar -C $LOCAL_IMAGE_TARGET_DIR -cpf ${WORKDIR}/container-images.tar overlay-layers overlay-images overlay
    sudo chmod ugo+r ${WORKDIR}/container-images.tar
}

do_install(){
    install -d ${D}/var/lib/containers
    install -m 0644 ${WORKDIR}/container-images.tar ${D}/var/lib/containers/container-images.tar
}
