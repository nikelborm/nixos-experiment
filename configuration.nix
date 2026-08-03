{
  config,
  lib,
  pkgs,
  ...
}:
{
  # --- REQUIRED for TPM2 auto-unlock -------------------------------
  # systemd stage-1 initrd is what actually talks to the TPM and honours
  # the `tpm2-device=auto` crypttab option that disko-config.nix sets on
  # the LUKS device. Without this, TPM unlock in initrd does NOT happen.
  boot.initrd.systemd.enable = true;

  # TPM2 userland on the running system, needed to run the one-time
  # `systemd-cryptenroll --tpm2-device=auto ...` enrollment.
  security.tpm2.enable = true;

  # The TPM kernel driver is normally auto-detected. Uncomment only if
  # early boot cannot find the chip.
  # boot.initrd.availableKernelModules = [ "tpm_crb" "tpm_tis" ];

  # Pairs cleanly with the systemd stage-1 initrd enabled above.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.efi.efiSysMountPoint = "/efi";

  # =================================================================
  # LATER: SECURE BOOT (lanzaboote) - kept commented until you set it up.
  # Enabling this and enrolling Secure Boot keys CHANGES PCR 7, so you
  # must then RE-ENROLL the TPM2 slot against PCR 7 and RE-VERIFY the
  # unlock at reboot (see the "RE-ENROLL AGAINST PCR 7" command in
  # disko-config.nix). Requires adding the lanzaboote flake input.
  # =================================================================
  # boot.loader.systemd-boot.enable = lib.mkForce false; # lanzaboote replaces it
  # boot.lanzaboote = {
  #   enable = true;
  #   pkiBundle = "/var/lib/sbctl";
  # };

  networking.hostName = "xiaomi-A35S-laptop-nixos";
  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Moscow";

  services.pipewire.enable = true;
  services.libinput.enable = true;

  users.users.evadev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    tree
    micro-with-wl-clipboard
    wget
    curl
  ];

  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # TODO enable only maybe for virtual machine?
  services.openssh.enable = true;

  networking.firewall.enable = false;

  # The NixOS release FIRST installed with; do not bump casually.
  system.stateVersion = "26.05";
}
