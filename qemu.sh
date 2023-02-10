#!/bin/bash

SCRIPT_DIR="$(dirname "$(realpath "${BASH_SOURCE:-$0}")")"

cd "${SCRIPT_DIR}/build/tmp-glibc/deploy/images/qemuarm/"

qemu-system-arm -nographic -machine virt -cpu cortex-a15 \
  -d unimp -m 1057 \
  -kernel barebox-dt-2nd.img \
  -device virtio-blk-device,drive=hd0 \
  -drive if=none,file=qemu-virt-image.qcow,id=hd0 \
  -virtfs local,id=rootfs,path=$(pwd),security_model=none,readonly,mount_tag=deploy

