#!/bin/bash
# -- Bash script used to create the base image for KVM Virtual Machines. 
# author: netlinux.mailtech@gmail.com

# ------------------------------------
#   G L O B A L    V A R I A B L E S
# ------------------------------------
# -- distribution name
DISTRO_NAME="none"
# -- distribution version
DISTRO_VERSION="none"
# -- server location containing an installable distribution image
DISTRO_IMAGE="none"

# -- name of the new guest virtual machine instance
VM_NAME="${DISTRO_NAME}-${DISTRO_VERSION}"
# -- path to media use as storage for the guest
VM_DISK_PATH="/var/lib/libvirt/images"
# -- size (in GB) to use if creating new storage
VM_DISK_SIZE="10G"
# -- memory to allocate for guest instance in megabytes
VM_RAM=1024
# -- number of virtual processors to configure for the guest
VM_CPU=1


# ----------------------
#   F U N C T I O N S
# ----------------------
# -- print help info
print_help() {
  echo "# Create the base image for KVM Virtual Machines
    usage:
      $1 [-h] [-d distro] [-v version] [-u iso_url]

    where:
      -h Show this help text
      -u Server location containing an installable distribution image (optional)
      -d Distribution name [centos, ubuntu, debian]
      -v Distribution version (optional)
         defaults: centos 7; ubuntu xenial; debian jessie

# Distro specific url:
centos -- http://mirror.i3d.net/pub/centos/<version>/os/x86_64/
ubuntu -- http://eu.archive.ubuntu.com/ubuntu/dists/<version>/main/installer-amd64/
debian -- http://ftp.eu.debian.org/debian/dists/<version>/main/installer-amd64/
"
}

# -- build virtual machine
build_vm() {
  # -- guest name
  local vm_name=$1
  # -- guest disk image
  local vm_disk="${VM_DISK_PATH}/$1.img"

  # -- create image path if not exists
  if [ ! -d "${VM_DISK_PATH}" ]; then
    mkdir -p ${VM_DISK_PATH}
  fi
  # -- create disk image for guest
  if [ -f ${vm_disk} ]; then
    read -p "Disk ${VM_DISK_PATH} exist. Remove? [y/n]" remove
    if [ "${remove}" == "y" ];then
      rm ${vm_disk}
      echo -e "OK. Removed ${vm_disk}"
      qemu-img create -f raw "${vm_disk}" ${VM_DISK_SIZE}
    else
      echo "Cannot create file ${vm_disk} because it already exists."
      exit 1
    fi
  else
    qemu-img create -f raw "${vm_disk}" ${VM_DISK_SIZE}
  fi
  # -- start building virtual machine
  virt-install --name $1 \
    --ram ${VM_RAM} \
    --vcpus=${VM_CPU} \
    --os-type=linux \
    --accelerate \
    --nographics -v \
    --location $2 \
    --network network=default \
    --disk path="${vm_disk}" \
    -x "console=ttyS0"
}


# ------------------------------
#   M A I N    F U N C T I O N
# ------------------------------
# -- parse command line arguments
while getopts ':h:d:v:u:' option; do
  case "${option}" in
    h) print_help $0; exit 0;;
    d) DISTRO_NAME=${OPTARG};;
    v) DISTRO_VERSION=${OPTARG};;
    u) DISTRO_IMAGE=${OPTARG};;
    *) print_help $0; exit 1;;
  esac
done

if [ $# == 0 ]; then
  print_help $(basename "$0")
  exit 1
elif [ "${DISTRO_IMAGE}" != "none" ]; then
  read -p "VM name: " VM_NAME
  build_vm ${VM_NAME} ${DISTRO_IMAGE}
elif [ "${DISTRO_NAME}" != "none" ]; then
  case ${DISTRO_NAME} in
    "centos")
      if [ "${DISTRO_VERSION}" == "none" ]; then
        DISTRO_VERSION="7"
      fi
      DISTRO_IMAGE="http://mirror.i3d.net/pub/centos/${DISTRO_VERSION}/os/x86_64/";;
    "ubuntu")
      if [ "${DISTRO_VERSION}" == "none" ]; then
        DISTRO_VERSION="xenial"
      fi
      DISTRO_IMAGE="http://us.archive.ubuntu.com/ubuntu/dists/${DISTRO_VERSION}/main/installer-amd64/";;
    "debian")
      if [ "${DISTRO_VERSION}" == "none" ]; then
        DISTRO_VERSION="jessie"
      fi
      DISTRO_IMAGE="http://ftp.us.debian.org/debian/dists/${DISTRO_VERSION}/main/installer-amd64/";;
  esac
  VM_NAME="${DISTRO_NAME}-${DISTRO_VERSION}"
  build_vm ${VM_NAME} ${DISTRO_IMAGE}
else
  echo "ERROR: Missing some parameters!!"
  echo -e "\nExample usage:
  $(basename "$0") -d ubuntu -v xenial
  $(basename "$0") -d centos -v 7
  $(basename "$0") -u http://ftp.us.debian.org/debian/dists/jessie/main/installer-amd64/"
fi
