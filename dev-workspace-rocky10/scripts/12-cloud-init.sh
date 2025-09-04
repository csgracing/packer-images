#!/bin/sh

set -e

dnf install -y cloud-init
systemctl enable cloud-init-local
systemctl enable cloud-init
systemctl enable cloud-config
systemctl enable cloud-final