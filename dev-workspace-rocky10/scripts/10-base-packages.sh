#!/bin/sh

set -e

# upgrade packages
dnf -y update

# install development tools group
dnf -y groupinstall "Development Tools"