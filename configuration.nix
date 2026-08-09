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

  boot.kernel.sysctl."kernel.sysrq" = true;
  networking.nftables.enable = true;
  # hardware.bluetooth.enable = true;
  #? rtkit (optional, recommended) allows Pipewire to use the realtime scheduler for increased performance
  security.rtkit.enable = true;
  services.pipewire.enable = true;

  networking.hostName = "xiaomi-A35S-laptop-nixos";
  networking.networkmanager.enable = true;
  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "Europe/Moscow";

  services.libinput.enable = true;

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;

  users.users.evadev = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
  };

  environment.systemPackages = with pkgs; [
    bun
    nodejs
    deno
    tree
    micro-with-wl-clipboard
    wget
    anytype
    throne
    btrfs-assistant
    btrfs-progs
    gimp
    meld
    git
    curl
    zip
    unzip
    fd
    eza
    croc
    lsof
    mosh
    tmux
    rsync
    zellij
    starship
    fastfetch
    systemctl-tui
    lazygit
    lazydocker
    _7zz-rar
    gh
    gcc
    git-lfs
    isd
    file
    tlrc
    aria2
    unrar
    yq-go
    yt-dlp
    hadolint
    pciutils
    usbutils
    qrencode
    ffmpeg-full
    strace
    inotify-tools
    psmisc
    lazysql
    pgcli
    litecli
    scrcpy
    fsearch
    obsidian
    libffi
    jq
    bat
    duf
    gdu
    fzf
    btop
    zoxide
    ripgrep
    nmap
    iperf
    tcpdump
    shfmt
    iotop
    fatrace
    devenv
    devbox
    lazyjournal
    nurl
    nix-tree
    hydra-check
    nix-output-monitor
    nixd
    nixfmt
    ncurses
    net-tools
    gawk
    procps
    gnused
    gnugrep
    openssh
    iproute2
    iputils
    inetutils
    diffutils
    findutils
    netcat-openbsd
    gparted-full
    htop
    btop-rocm
    recordbox
    noctalia-shell
    fuzzel
    swaylock
    transmission-gtk
    niri
    imhex
    kitty
  ];

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${config.programs.niri.package}/bin/niri-session";
        user = "evadev";
      };
    };
  };

  # Ensures environment PATH variables pass cleanly to user systemd services
  systemd.user.services.niri.enableDefaultPath = false;

  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Force Electron apps to use Wayland

  environment.variables.TERMINAL = "kitty";

  # TODO enable only maybe for virtual machine?
  services.openssh.enable = true;

  networking.firewall.enable = false;

  # The NixOS release FIRST installed with; do not bump casually.
  system.stateVersion = "26.05";
}
