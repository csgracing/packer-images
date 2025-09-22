# based on:
# https://github.com/rocky-linux/kickstarts/blob/cb3b8edabf47f8a6586e1996eb4bf1adb81437d1/live/10/x86_64/rocky-live-base.ks

# rocky-live-base.ks
#
# Base installation information for Rocky Linux images
#

lang en_GB.UTF-8
keyboard gb
timezone Europe/London
# selinux --enforcing
firewall --enabled --service=mdns
skipx
zerombr
clearpart --all

reqpart --add-boot
part swap --fstype=swap --size=2048
part / --fstype=xfs --size=1024 --grow

services --enabled=NetworkManager
network --bootproto=dhcp --device=link --activate
rootpw --lock --iscrypted locked
# shutdown
reboot

repo --name=BaseOS --cost=200 --baseurl=https://rockylinux.mirrorservice.org/pub/rocky/10/BaseOS/$basearch/os/
repo --name=AppStream --cost=200 --baseurl=https://rockylinux.mirrorservice.org/pub/rocky/10/AppStream/$basearch/os/
repo --name=CRB --cost=200 --baseurl=https://rockylinux.mirrorservice.org/pub/rocky/10/CRB/$basearch/os/
repo --name=extras --cost=200 --baseurl=https://rockylinux.mirrorservice.org/pub/rocky/10/extras/$basearch/os

# URL to the base os repo
url --url=http://dl.rockylinux.org/pub/rocky/10/BaseOS/$basearch/os/


%packages --ignoremissing
@core
@base
sudo
qemu-guest-agent
-dracut-config-rescue
-plymouth*
-iwl*firmware
openssh-server

# Required for SVG rnotes images

# RHBZ#1242586 - Required for initramfs creation
dracut-live
syslinux

# This isn't in @core anymore, but livesys still needs it
initscripts
chkconfig
%end

%post

systemctl enable sshd
systemctl start sshd
#systemctl disable firewalld

# Need for host/guest communication
systemctl enable qemu-guest-agent
systemctl start qemu-guest-agent

systemctl enable livesys.service
systemctl enable livesys-late.service
# Enable tmpfs for /tmp - this is a good idea
systemctl enable tmp.mount

# make it so that we don't do writing to the overlay for things which
# are just tmpdirs/caches
# note https://bugzilla.redhat.com/show_bug.cgi?id=1135475
cat >> /etc/fstab << EOF
vartmp   /var/tmp    tmpfs   defaults   0  0
EOF

# PackageKit likes to play games. Let's fix that.
rm -f /var/lib/rpm/__db*
releasever=$(rpm -q --qf '%{version}\n' --whatprovides system-release)
basearch=$(uname -i)
rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-Rocky-10
echo "Packages within this LiveCD"
rpm -qa
# Note that running rpm recreates the rpm db files which aren't needed or wanted
rm -f /var/lib/rpm/__db*

# go ahead and pre-make the man -k cache (#455968)
/usr/bin/mandb

# make sure there aren't core files lying around
rm -f /core*

# remove random seed, the newly installed instance should make it's own
rm -f /var/lib/systemd/random-seed

# convince readahead not to collect
# FIXME: for systemd

echo 'File created by kickstart. See systemd-update-done.service(8).' \
    | tee /etc/.updated >/var/.updated

# Drop the rescue kernel and initramfs, we don't need them on the live media itself.
# See bug 1317709
rm -f /boot/*-rescue*

# Disable network service here, as doing it in the services line
# fails due to RHBZ #1369794 - the error is expected
systemctl disable network

# Remove machine-id on generated images
rm -f /etc/machine-id
touch /etc/machine-id

# relabel
#/usr/sbin/restorecon -RF /
/usr/sbin/fixfiles -R -a restore


# packer
# Newly created users need the file/folder framework for SSH key authentication.
umask 0077
mkdir /etc/skel/.ssh
touch /etc/skel/.ssh/authorized_keys

# Loop over the command line. Set interesting variables.
for x in $(cat /proc/cmdline)
do
  case $x in
    PACKER_USER=*)
      PACKER_USER="${x#*=}"
      ;;
    PACKER_AUTHORIZED_KEY=*)
      # URL decode $encoded into $PACKER_AUTHORIZED_KEY
      encoded=$(echo "${x#*=}" | tr '+' ' ')
      printf -v PACKER_AUTHORIZED_KEY '%b' "${encoded//%/\\x}"
      ;;
  esac
done

# Create/configure packer user, if any.
if [ -n "$PACKER_USER" ]
then
  useradd $PACKER_USER
  echo "%$PACKER_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers.d/$PACKER_USER
  [ -n "$PACKER_AUTHORIZED_KEY" ] && echo $PACKER_AUTHORIZED_KEY >> $(eval echo ~"$PACKER_USER")/.ssh/authorized_keys
fi

%end
