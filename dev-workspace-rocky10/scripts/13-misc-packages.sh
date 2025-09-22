#!/bin/sh

set -e

sudo dnf config-manager --enable crb
sudo dnf install -y ninja-build cmake python-pip
pip install gcovr
