#!/bin/bash
# © Copyright 2015 Hewlett Packard Enterprise Development LP
set -e

# Usage: configure_docker.sh <DEVICE_MAPPER_VOLUME> <DEVICE_MAPPER_SIZE>

read -d '' usage <<PATCH || true
Usage (needs root):
  configure_docker.sh <DEVICE_MAPPER_VOLUME> <DEVICE_MAPPER_SIZE>

  DEVICE_MAPPER_VOLUME - e.g. /dev/sdb
  DEVICE_MAPPER_DATA_SIZE - size in GB (e.g. 60); Note will be divided into
    PADDING+METADATA+DATA at percentages 3%,6%,91% respectively with some
    healthy maximums on metadata/padding.
PATCH

# Process arguments

if [ -z ${1} ]; then echo "${usage}"; exit 1; else DEVICE_MAPPER_VOLUME=$1; fi
if [ -z ${2} ]; then echo "${usage}"; exit 1; else DEVICE_MAPPER_SIZE=$2; fi

# 91% Data
# 6%  Metadata, Max 8GB
# 3%  Padding,  Max 4GB
DEVICE_MAPPER_PADDING=$(python3 -c "print(int(min(4, ${DEVICE_MAPPER_SIZE} * 0.03)))")
DEVICE_MAPPER_METADATA_SIZE=$(python3 -c "print(int(min(8, ${DEVICE_MAPPER_SIZE} * 0.06)))")
DEVICE_MAPPER_DATA_SIZE=$(python3 -c "print(${DEVICE_MAPPER_SIZE}-${DEVICE_MAPPER_PADDING}-${DEVICE_MAPPER_METADATA_SIZE})")

# Setup devicemapper via logical volume management

service docker stop
pvcreate -ff -y    $DEVICE_MAPPER_VOLUME
pvs

vgcreate vg-docker $DEVICE_MAPPER_VOLUME
vgs

echo ___ LV data
lvcreate -L ${DEVICE_MAPPER_DATA_SIZE}G     -n data     vg-docker
lvs

echo ___ LV metadata
lvcreate -L ${DEVICE_MAPPER_METADATA_SIZE}G -n metadata vg-docker
lvs

# Insert the device information into the docker configuration

dopts="--storage-driver=devicemapper"
dopts="$dopts --storage-opt dm.datadev=/dev/vg-docker/data"
dopts="$dopts --storage-opt dm.metadatadev=/dev/vg-docker/metadata"
dopts="$dopts --storage-opt dm.basesize=100G"

for var in http_proxy https_proxy no_proxy HTTP_PROXY HTTPS_PROXY NO_PROXY ; do
  if test -n "${!var}" ; then
    echo "export ${var}=${!var}" >> /etc/default/docker
  fi
done

echo ___ Insert
echo DOCKER_OPTS=\"$dopts\" | tee -a /etc/default/docker

# Activate the now-configured system

service docker start
