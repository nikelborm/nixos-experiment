#!/usr/bin/env bash
set -euxo pipefail

# Very important detail I learned recently is that when mounting many different
# subvolumes from the same device, the compress option of the first subvolume
# applies to the whole filesystem and all other mounted subvolumes, so I need
# to call `btrfs property set` manually to actually control this the way I want

# Important detail for chattr: lowercase c is compression, uppercase C is nocow

root_subvolume=./@arch_root

# "/"
btrfs property set $root_subvolume/ compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 $root_subvolume/


# "/home"
mkdir -p $root_subvolume/home
btrfs property set $root_subvolume/home compression zstd
btrfs property set ./@home compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@home

# "/home/evadev/.cache"
mkdir -p ./@home/evadev/.cache
chattr -mc ./@home_evadev_.cache ./@home/evadev/.cache
#! nocow, because has writes often and doesn't compress well (compression
#! is not supported with nocow) a separate partition to exclude from snapshots
chattr +C  ./@home_evadev_.cache ./@home/evadev/.cache
chown -R 1000:1000 ./@home_evadev_.cache ./@home/evadev
btrfs filesystem defragment -r -f --nocomp ./@home_evadev_.cache

# "/home/evadev/.vagrant.d/boxes"
mkdir -p ./@home/evadev/.vagrant.d/boxes
btrfs property set ./@home_evadev_.vagrant.d_boxes compression zstd
btrfs property set ./@home/evadev/.vagrant.d/boxes compression zstd
touch ./@home_evadev_.vagrant.d_boxes/.gitkeep
#! no point in making it nocow, because live images live elsewhere
#! and we can also compress base images
chown -R 1000:1000 ./@home_evadev_.vagrant.d_boxes ./@home/evadev/.vagrant.d
btrfs filesystem defragment -r -f -czstd -L 15 ./@home_evadev_.vagrant.d_boxes

# "/var/lib/libvirt/qemu/save"
mkdir -p $root_subvolume/var/lib/libvirt/qemu/save
btrfs property set ./@var_lib_libvirt_qemu_save compression zstd
btrfs property set $root_subvolume/var/lib/libvirt/qemu/save compression zstd
chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_save $root_subvolume/var/lib/libvirt/qemu/save
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_save

# "/var/lib/libvirt/qemu/dump"
mkdir -p $root_subvolume/var/lib/libvirt/qemu/dump
btrfs property set ./@var_lib_libvirt_qemu_dump compression zstd
btrfs property set $root_subvolume/var/lib/libvirt/qemu/dump compression zstd
chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_dump $root_subvolume/var/lib/libvirt/qemu/dump
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_dump

# "/var/lib/libvirt/qemu/ram"
mkdir -p $root_subvolume/var/lib/libvirt/qemu/ram
btrfs property set ./@var_lib_libvirt_qemu_ram compression zstd
btrfs property set $root_subvolume/var/lib/libvirt/qemu/ram compression zstd
chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_ram $root_subvolume/var/lib/libvirt/qemu/ram
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_ram

# "/var/lib/libvirt/images"
mkdir -p $root_subvolume/var/lib/libvirt/images
chattr -mc ./@var_lib_libvirt_images $root_subvolume/var/lib/libvirt/images
#! nocow on images because it has heavy random-like updates
#! mount without compression, because nocow doesn't support it
chattr +C  ./@var_lib_libvirt_images $root_subvolume/var/lib/libvirt/images
chmod ug+x ./@var_lib_libvirt_images $root_subvolume/var/lib/libvirt/images
chown root:libvirt ./@var_lib_libvirt_images $root_subvolume/var/lib/libvirt/images
btrfs filesystem defragment -r -f --nocomp ./@var_lib_libvirt_images

# "/var/lib/libvirt/boot"
mkdir -p $root_subvolume/var/lib/libvirt/boot
btrfs property set ./@var_lib_libvirt_boot compression zstd
btrfs property set $root_subvolume/var/lib/libvirt/boot compression zstd
#! sticky bit so that people can freely add images and it will get libvirt
#! group instead of file creator group
chmod g+s ./@var_lib_libvirt_boot $root_subvolume/var/lib/libvirt/boot
chown root:libvirt ./@var_lib_libvirt_boot $root_subvolume/var/lib/libvirt/boot
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_boot

# "/var/lib/ollama"
mkdir -p $root_subvolume/var/lib/ollama
chown ollama:ollama ./@var_lib_ollama $root_subvolume/var/lib/ollama
mkdir -p $root_subvolume/var/lib/ollama/.cache
chattr -mc $root_subvolume/var/lib/ollama/.cache
chattr +C $root_subvolume/var/lib/ollama/.cache
btrfs property set ./@var_lib_ollama compression none
btrfs property set $root_subvolume/var/lib/ollama compression none
mkdir -p ./@var_lib_ollama/blobs
btrfs filesystem defragment -r -f --nocomp ./@var_lib_ollama

# "/var/lib/docker"
mkdir -p $root_subvolume/var/lib/docker
btrfs property set ./@var_lib_docker compression zstd
btrfs property set $root_subvolume/var/lib/docker compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_docker

# "/var/lib/containers"
mkdir -p $root_subvolume/var/lib/containers
btrfs property set ./@var_lib_containers compression zstd
btrfs property set $root_subvolume/var/lib/containers compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_containers

# "/var/lib/containerd"
mkdir -p $root_subvolume/var/lib/containerd
btrfs property set ./@var_lib_containerd compression zstd
btrfs property set $root_subvolume/var/lib/containerd compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_containerd

# "/var/lib/rancher"
mkdir -p $root_subvolume/var/lib/rancher
btrfs property set ./@var_lib_rancher compression zstd
btrfs property set $root_subvolume/var/lib/rancher compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_rancher

# "/var/lib/kubelet"
mkdir -p $root_subvolume/var/lib/kubelet
btrfs property set ./@var_lib_kubelet compression zstd
btrfs property set $root_subvolume/var/lib/kubelet compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_kubelet

# "/big_media"
mkdir -p $root_subvolume/big_media
chown -R 1000:1000 ./@big_media $root_subvolume/big_media
chmod +rwx ./@big_media $root_subvolume/big_media
btrfs property set ./@big_media compression zstd
btrfs property set $root_subvolume/big_media compression zstd
btrfs filesystem defragment -r -f -czstd -L 15 ./@big_media

# "/var/cache"
mkdir -p $root_subvolume/var/cache
chattr -mc $root_subvolume/var/cache
chattr +C ./@var_cache $root_subvolume/var/cache
btrfs filesystem defragment -r -f --nocomp ./@var_cache

# "/var/log"
mkdir -p $root_subvolume/var/log
chattr -mc $root_subvolume/var/log
chattr +C ./@var_log $root_subvolume/var/log
btrfs filesystem defragment -r -f --nocomp ./@var_log

# "/var/tmp"
mkdir -p $root_subvolume/var/tmp
chattr -mc $root_subvolume/var/tmp
chattr +C ./@var_tmp $root_subvolume/var/tmp
chmod +t ./@var_tmp $root_subvolume/var/tmp
btrfs filesystem defragment -r -f --nocomp ./@var_tmp
