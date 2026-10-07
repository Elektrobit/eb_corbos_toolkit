# Ankaios Integration Guide

Ankaios is an official feature of the EB corbos Toolkit. The feature is maintained in this
repository and is enabled by adding [kas/features/public/ankaios.yml](kas/features/public/ankaios.yml) to an image build.
It installs the Ankaios server, agent, CLI, Podman runtime, crinit startup configuration, and
the container images used by the included vehicle-signals demonstration.

Ankaios is integrated into the fastdev image and into coredev build images.
It runs inside the Low Integrity VM (LiVM) and the [vehicle signals tutorial](https://eclipse-ankaios.github.io/ankaios/1.0/usage/tutorial-vehicle-signals/) container images are preinstalled on the rootfs at build time and starts on boot of the image. In addition, the Ankaios Dashboard container is installed for visualized workload overview and for debugging purposes.

## Build the FastDev image

Build FastDev with the Ankaios feature enabled:

```sh
kas build --target fastdev kas/references/public.yml:kas/features/public/ankaios.yml
```

Run the resulting image in QEMU:

```sh
./scripts/qemu.sh -t fastdev --mem 2048
```

## Validate Ankaios workloads

Ankaios starts automatically at boot and loads the built-in startup manifest. On the target,
use the Ankaios CLI to inspect the workloads:

```sh
ank get workloads
```

The workload list includes the Ankaios Dashboard, KUKSA databroker, speed provider, and speed
consumer. Validate that the consumer receives vehicle speed data:

```sh
ank logs thirdparty_speed-consumer
```

Expected output contains messages similar to:

```text
Received updated speed: 0.0
Received updated speed: 1.0
Received updated speed: 2.0
...
```

**Note:** Because of a network race condition in crinit providing the network service, the start of the Ankaios Server and all container images might fail. In this case stop the server and the agent with `crinit-ctl stop ank-agent` and `crinit-ctl stop ank-server` and restart them with `crinit-ctl restart ank-server` and `crinit-ctl restart ank-agent`. Afterwards you should see all container images with execution state `Running(Ok)` and the Ankaios Dashboard should be accessible on port 5001.

## Access the Ankaios Dashboard

The dashboard runs on port 5001. When using QEMU, forward the port from a separate host
terminal:

```sh
ssh -N -L 5001:127.0.0.1:5001 -p 10022 root@localhost
```

Open http://127.0.0.1:5001 in a browser and authenticate with password `admin`.

## Build for S32G2

Build the coredev image for the S32G274A RDB2 with Ankaios enabled:

```sh
kas build --target coredev kas/references/core.yml:kas/machines/core/s32g274ardb2.yml:kas/features/public/ankaios.yml
```

Use the standard Toolkit flashing workflow for the resulting S32G2 image.

## Update the Ankaios version

The Ankaios Debian package recipes are generated from the official Ankaios APT repository. To
update them, run reposync from the Ankaios feature layer:

```sh
cd layers/meta-features-public/meta-features-public-ankaios/
ebcl-reposync -c "meta-features-public-ankaios-packages.yml"
```

Review and commit the regenerated recipes with the corresponding feature update.
