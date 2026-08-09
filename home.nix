{ pkgs, config,lib, ... }:
let
  replaceDesktopItem =
    package: name: newExec:
    (pkgs.runCommand name { } ''
      mkdir -p $out
      src=${package}/share/applications/${name}
      sed 's|^Exec=.*$|Exec=${newExec}|' "$src" > $out/${name}
    '')
    + /${name};

  terminalApps = [
    # TODO: proper desktop file
    "kitty.desktop"
  ];

in
{
  xdg.autostart = {
    enable = true;
    entries = [
      # (replaceDesktopItem pkgs.throne "throne.desktop"
      #   "${pkgs.throne}/share/throne/Throne -tray -appdata"
      # )
      # extraConfig = {
      #   "X-KDE-autostart-after" = "panel";
      # };
      # outName = "Throne.desktop";

      # (replaceDesktopItem pkgs.ayugram-desktop "com.ayugram.desktop.desktop" "AyuGram -autostart")
      # (replaceDesktopItem config.programs.nixcord.finalPackage.discord "discord.desktop"
      #   "Discord --start-minimized"
      # )
      # (replaceDesktopItem config.programs.nixcord.finalPackage.vesktop "vesktop.desktop"
      #   "vesktop --start-minimized"
      # )

      #? Requires & After tray.target
      # (replaceDesktopItem pkgs.syncthingtray "syncthingtray.desktop"
      #   "syncthingtray qt-widgets-gui --single-instance --wait"
      # )
      # extraConfig = {
      #   "X-GNOME-Autostart-Delay" = 0;
      #   "X-GNOME-Autostart-enabled" = true;
      #   "X-LXQt-Need-Tray" = true;
      # };

      # (replaceDesktopItem config.programs.keepassxc.package "org.keepassxc.KeePassXC.desktop" "keepassxc")
    ];
  };

  xdg.configFile."niri/config.kdl".text = ''
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
      Mod+Return { spawn "kitty"; }
      Mod+D { spawn "fuzzel"; }
    }
  '';


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
      single_instance = "yes";
    };
    # TODO:
    # keybindings = {
    #   "kitty_mod+f" = "launch --allow-remote-control kitty +kitten kitty_search/search.py @active-kitty-window-id";
    # };
  };

  xdg.mimeApps.associations.added."application/x-shellscript" = lib.mkBefore terminalApps;
  xdg.mimeApps.defaultApplications."application/x-shellscript" = lib.mkBefore terminalApps;
  xdg.terminal-exec.settings.default = "kitty.desktop";
}
