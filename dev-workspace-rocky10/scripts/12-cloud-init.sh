#!/bin/sh

set -e

dnf install -y cloud-init
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final

# Remove cloud-init artifacts to simulate clean instance
# Should re-run cloud-init on subsequent boot.
# Ref: https://cloudinit.readthedocs.io/en/latest/reference/cli.html
# https://cloudinit.readthedocs.io/en/latest/howto/rerun_cloud_init.html
cloud-init clean --logs --configs=all --seed