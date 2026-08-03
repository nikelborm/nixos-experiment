{ config, lib, pkgs, modulesPath, disko, ... }: {
  imports =
    [
      # the final layout turned out to be different in small details, becase I
      # couldn't just wipe the disk and apply disko config to it, so I just do
      # manual rewrite of everything relevant
      ./disko-fixed-render.nix
    ];

  # ???????
  # boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "sr_mod" "virtio_blk" ];
  # boot.initrd.kernelModules = [ "dm-snapshot" ];
  # boot.kernelModules = [ "kvm-amd" ];
  # boot.extraModulePackages = [ ];

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
