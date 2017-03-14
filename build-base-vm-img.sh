#!/bin/bash
# -- Build base image for KVM Virtual Machines
# author: netlinux.mailtech@gmail.com

# -- OS parameters
DISTRO_NAME="null"
DISTRO_VERSION="null"
DISTRO_LOCATION="null"
# -- VM parameters
VM_NAME="${DISTRO_NAME}-${DISTRO_VERSION}"
VM_DISK_PATH="/var/lib/libvirt/images"
VM_DISK_SIZE="10G"
VM_RAM=1024
VM_CPU=1

# -- print help info
print_help(){
        echo "# Built base image for KVM Virtual Machines
    usage:
      $1 [-h] [-d distro] [-v version] [-u iso_url]

    where:
      -h show this help text
      -u specific distro url (optional)
      -d specific distro name [centos, ubuntu, debian]
      -v specific distro version (optional)
         defaults: centos 7; ubuntu xenial; debian jessie

# Distro specific url:
centos -- http://mirror.i3d.net/pub/centos/<version>/os/x86_64/
ubuntu -- http://eu.archive.ubuntu.com/ubuntu/dists/<version>/main/installer-amd64/
debian -- http://ftp.eu.debian.org/debian/dists/<version>/main/installer-amd64/
"
}

# -- build VM
build_vm(){

  local vm_name=$1
  local vm_disk="${VM_DISK_PATH}/$1.img"

  # -- images path
  if [ ! -d "${VM_DISK_PATH}" ]; then
    mkdir -p ${VM_DISK_PATH}
  fi

  if [ -f ${vm_disk} ]; then
    read -p "Disk ${VM_DISK_PATH} exist. Remove? [y/n]" remove
    if [ "${remove}" == "y" ];then
      rm ${vm_disk}
      echo -e "OK. Removed ${vm_disk}"
    fi
    qemu-img create -f raw "${vm_disk}" ${VM_DISK_SIZE}
  else
    qemu-img create -f raw "${vm_disk}" ${VM_DISK_SIZE}
  fi

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

# -- parse command line arguments
if [ $# == 0 ]; then
  print_help $(basename "$0")
  exit 1
fi

while getopts ':h:d:v:u:' option; do
  case "${option}" in
    h) print_help $0; exit 0;;
    d) DISTRO_NAME=${OPTARG};;
    v) DISTRO_VERSION=${OPTARG};;
    u) DISTRO_LOCATION=${OPTARG};;
    *) print_help $0; exit 1;;
  esac
done

if [ "${DISTRO_LOCATION}" != "null" ]; then
  read -p "VM name: " VM_NAME
  build_vm ${VM_NAME} ${DISTRO_LOCATION}
elif [ "${DISTRO_NAME}" != "null" ]; then
  case ${DISTRO_NAME} in
    "centos")
      if [ "${DISTRO_VERSION}" == "null" ]; then
        DISTRO_VERSION="7"
      fi
      DISTRO_LOCATION="http://mirror.i3d.net/pub/centos/${DISTRO_VERSION}/os/x86_64/";;
    "ubuntu")
      if [ "${DISTRO_VERSION}" == "null" ]; then
        DISTRO_VERSION="xenial"
      fi
      DISTRO_LOCATION="http://us.archive.ubuntu.com/ubuntu/dists/${DISTRO_VERSION}/main/installer-amd64/";;
    "debian")
      if [ "${DISTRO_VERSION}" == "null" ]; then
        DISTRO_VERSION="jessie"
      fi
      DISTRO_LOCATION="http://ftp.us.debian.org/debian/dists/${DISTRO_VERSION}/main/installer-amd64/";;
  esac
  VM_NAME="${DISTRO_NAME}-${DISTRO_VERSION}"
  build_vm ${VM_NAME} ${DISTRO_LOCATION}
else
  echo "ERROR: Missing some parameters!!"
  echo -e "\nExample usage:
  $(basename "$0") -d ubuntu -v xenial
  $(basename "$0") -d centos -v 7
  $(basename "$0") -u http://ftp.us.debian.org/debian/dists/jessie/main/installer-amd64/"
fi
