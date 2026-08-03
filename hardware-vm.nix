{ config, lib, pkgs, modulesPath, disko, ... }: {
  imports =
    [
      (modulesPath + "/profiles/qemu-guest.nix")
      # in vm we can afford to wipe the whole disk, so disko's generated
      # params are correct
      disko.nixosModules.disko
      ./disko-config.nix
    ];

  boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  boot.initrd.kernelModules = [ "dm-snapshot" ];
  boot.kernelModules = [ "kvm-amd" ];
  boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
