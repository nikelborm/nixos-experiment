# nix repl --experimental-features "nix-command flakes"
# :lf .
# :p nixosConfigurations.xiaomi-A35S-laptop.config.fileSystems
# :p nixosConfigurations.xiaomi-A35S-laptop.config.swapDevices
# :p nixosConfigurations.xiaomi-A35S-laptop.config.boot.initrd.luks.devices
# :p nixosConfigurations.xiaomi-A35S-laptop.config.boot.resumeDevice
{
  config,
  lib,
  pkgs,
  ...
}:
let
  mkval =
    mountpoint:
    let
      relative = builtins.substring 1 (builtins.stringLength mountpoint) mountpoint;
      subvol_opt = "subvol=/@" + builtins.replaceStrings [ "/" ] [ "_" ] relative;
    in
    {
      # TODO: potentially change to "/dev/mapper/pool-root" in such cases?
      device = "/dev/pool/root";
      fsType = "btrfs";
      options = [
        "noatime"
        "compress=zstd"
        "ssd"
        "space_cache=v2"
        subvol_opt
      ];
    };
in
{
  fileSystems =
    (lib.genAttrs [
      "/"
      "/home"
      # "/big_media"
      # "/home/evadev/.cache"
      # "/home/evadev/.vagrant.d/boxes"
      # "/var/cache"
      # "/var/lib/containerd"
      # "/var/lib/containers"
      # "/var/lib/docker"
      # "/var/lib/kubelet"
      # "/var/lib/libvirt/boot"
      # "/var/lib/libvirt/images"
      # "/var/lib/libvirt/qemu/dump"
      # "/var/lib/libvirt/qemu/ram"
      # "/var/lib/libvirt/qemu/save"
      # "/var/lib/ollama"
      # "/var/lib/rancher"
      # "/var/log"
      # "/var/tmp"
    ] mkval)
    // {
      "/efi" = {
        device = "/dev/disk/by-partlabel/disk-main-ESP";
        fsType = "vfat";
        options = [ "umask=0077" ];
      };
    };
  swapDevices = [
    {
      device = "/dev/pool/swap";
      deviceName = "dev-pool-swap";
      discardPolicy = "both";
      priority = 0;
    }
  ];
  boot.resumeDevice = "/dev/pool/swap";
  boot.initrd.luks.devices = {
    crypted = {
      allowDiscards = true;
      bypassWorkqueues = true;
      crypttabExtraOpts = [ "tpm2-device=auto" ];
      device = "/dev/disk/by-partlabel/disk-main-luks";
    };
  };
}
