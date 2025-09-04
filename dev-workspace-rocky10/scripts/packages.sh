#!/bin/sh

set -e

dnf -y update

dnf -y groupinstall "Dev Environment"

dnf -y install \
    gcc-arm-none-eabi \
    openocd \
    cmake \
    git \
    python3-pip \
    neovim \
    tmux \
    which \
    net-tools \
    unzip \
    ca-certificates \
    ripgrep \
    fzf \
    nodejs \
    npm \
    openssl \
    wireshark-cli \
    postgresql \
    zip \
    nmap \
    nmap-ncat \
    iproute \
    iputils \
    traceroute \
    patch \
    sshpass \
    syslinux \
    make \
    bat \
    gdb \
    gcc \
    clang \
    jq \
    wget \
    rsync \
    golang \
    ansible \

dnf clean all