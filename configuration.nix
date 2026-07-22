{
  config,
  lib,
  pkgs,
  ...
}:
{
  # ===================================================================
  # Runtime (installed-system) settings that the LUKS + TPM2 unlock in
  # disko-config.nix depends on. Imported by flake.nix alongside the
  # disko module and disko-config.nix.
  # ===================================================================

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

  # --- Boot loader -------------------------------------------------
  # systemd-boot on the unencrypted ESP (/boot is mounted by
  # disko-config.nix). It pairs cleanly with the systemd stage-1 initrd
  # enabled above.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  # --- Minimal system identity (fill in for a real install) --------
  # networking.hostName = "myhost";
  # time.timeZone = "Europe/Moscow";
  # users.users.nikel = {
  #   isNormalUser = true;
  #   extraGroups = [ "wheel" ];
  # };

  # Set to the NixOS release you FIRST installed with; do not bump casually.
  # system.stateVersion = "25.05";
}
