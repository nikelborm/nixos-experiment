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

  environment.etc."xdg/niri/config.kdl".text = ''
    spawn-at-startup "noctalia-shell"

    input {
        touchpad {
            tap
            natural-scroll
        }
    }

    layout {
        gaps 12
    }

    binds {
        Mod+Shift+Q { quit; }
        Mod+Return { spawn "alacritty"; }
        Mod+D { spawn "fuzzel"; }
    }
  '';

  programs.niri.enable = true;
  security.polkit.enable = true;
  services.gnome.gnome-keyring.enable = true;
  environment.sessionVariables.NIXOS_OZONE_WL = "1"; # Force Electron apps to use Wayland

  programs.kitty = {
    enable = true;
    font = {
      # JetBrains Mono NL is the no-ligatures version of JetBrains Mono font.
      # Useful command: kitty list-fonts
      # example of mono and propo: https://github.com/ryanoasis/nerd-fonts/issues/1703#issuecomment-2323803360
      # 1. Mono is truly mono and doesn't break the grid
      # 2. default without mono and propo visually still takes more than one cell, but doesn't break the grid, it just overlaps the character after them
      # 3. propo (proportional) (NO FUCKING T IN PROPO) takes as much space as it's rendered on. So characters following for example  shifted and grid broken
      # The best option is of course 1.
      # To show such best fonts execute `best_nerd_mono_fonts`
      name = "JetBrainsMono NFM SemiBold";
      package = pkgs.nerd-fonts.jetbrains-mono;
      size = 18.0;
    };
    launchOptions = [
      "--single-instance"
      "--listen-on=unix:/tmp/my-kitty-socket"
    ];
    settings = {
      bold_font = "JetBrainsMono NFM ExtraBold";
      italic_font = "JetBrainsMono NFM SemiBold Italic";
      bold_italic_font = "JetBrainsMono NFM ExtraBold Italic";

      # font_family FiraCode Nerd Font Mono

      hide_window_decorations = "True";
      scrollback_lines = 100000;

      background_opacity = "1.0";
      # background_image /home/evadev/Pictures/Love_Wallpapers/black/4K-OLED-HD-Wallpaper.png
      background_image_layout = "scaled";
      background_tint = "0.7";

      enable_audio_bell = "no";
      touch_scroll_multiplier = "8.0";
      wheel_scroll_multiplier = "8.0";
      copy_on_select = "yes";

      # so that copiying in micro would work
      clipboard_control = "write-clipboard write-primary read-clipboard read-primary";
    };
    # TODO:
    # keybindings = {
    #   "kitty_mod+f" = "launch --allow-remote-control kitty +kitten kitty_search/search.py @active-kitty-window-id";
    # };
  };

  environment.variables.TERMINAL = "kitty";

  #   let
  #   terminalApps = [
  #     # TODO: proper desktop file
  #     "kitty.desktop"
  #   ];
  # in
  # {
  #   xdg.mimeApps.associations.added."application/x-shellscript" = lib.mkBefore terminalApps;
  #   xdg.mimeApps.defaultApplications."application/x-shellscript" = lib.mkBefore terminalApps;
  #   xdg.terminal-exec.settings.default = "kitty.desktop";
  # }

  environment.etc."xdg/mimeapps.list".text = ''
    [Default Applications]
    application/x-shellscript=kitty.desktop

    [Added Associations]
    application/x-shellscript=kitty.desktop;
  '';

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
