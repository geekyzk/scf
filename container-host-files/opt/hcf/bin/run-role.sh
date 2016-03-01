#!/bin/bash
# (re)Start one or more specific roles.
# Assume that everything else is already active.
set -e

if [ $# -ne 1 ]
then
    echo 1>&2 "Usage: $(basename "$0") role"
    exit 1
else
    role_name="$1"
fi

# Terraform, in HOS/MPC VM, hcf-infra container support as copied
# SELF    = /opt/hcf/bin/list-roles.sh
# SELFDIR = /opt/hcf/bin
# ROOT    = /            (3x .. from SELFDIR)
#
# Vagrant
# SELF    = PWD/container-host-files/opt/hcf/bin/list-roles.sh
# SELFDIR = PWD/container-host-files/opt/hcf/bin
# ROOT    = PWD/container-host-files             (3x .. from SELFDIR)

SELFDIR="$(readlink -f "$(cd "$(dirname "$0")" && pwd)")"
ROOT="$(readlink -f "$SELFDIR/../../../")"

. "${ROOT}/opt/hcf/bin/common.sh"

# Vagrant has .runrc 2 level up in the mounted hierarchy.
# Terraform has no such copied to its VM, thus requires defaults.

if [ -f "${ROOT}/../bin/.runrc" ] ; then
    . "${ROOT}/../bin/.runrc"
else
    HCF_RUN_STORE="$HOME/.run/store"
    HCF_RUN_LOG_DIRECTORY="$HOME/.run/log"
    HCF_OVERLAY_GATEWAY="192.168.252.1"
fi

store_dir=$HCF_RUN_STORE
log_dir=$HCF_RUN_LOG_DIRECTORY
hcf_overlay_gateway=$HCF_OVERLAY_GATEWAY

# (Re)start the specified role
handle_restart "$role_name" \
    "$hcf_overlay_gateway" \
    "${ROOT}/bin/dev-settings.env" \
    "${ROOT}/bin/dev-certs.env" \
    || true

exit 0
