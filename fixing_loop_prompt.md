I'm trying to compile this config (git cloned into /etc/nixos on the virtual machine) with this command:
git pull; nixos-rebuild switch --flake .

The initial repo is owned by my friend. I'm trying to adopt it to my needs and was in the process of cleanup/adoption. Expect to see potentially unnessecary, half/under-cleaned up, or the stuff that was deleted accidentally (over-cleanup) because I didn't realize I would need it later. The friend has "coolvm". I DONT USE THAT! I HAVEN'T GOTTEN THAT DEEP INTO NIX!!! I just build the laptop version right inside the VM, because getting nixos on the laptop is the first thing I want to do! only then I plan to learn what's this coolvm. Right now I'm on arch linux, and I launched the VM through the gui Virtual Machine Manager.

You're on a `cleanup` git branch. The vm has the same branch as HEAD. The VM runs the xiaomi-A35S-laptop-nixos hostname (it's present in the config as well, and this is what will be deployed to notebook), user evadev. No need to verify that, it's true.

If you discovered a simpler option for my request, like instead me asking to install a flake, you found something in home manager, SUGGEST IT TO ME!

The target is a local virtual machine. I want to ensure it works in VM first and only then deploy to my notebook. You have the freedom to run any command inside the VM:
ssh root@192.168.122.35

The ssh command above should just work and you're free to explore the specifics about the environment, the machine, or the config that are wrong. Any modifications to the config MUST be created inside the local folder you're in right now (the branches here and on the vm are same, so you just need to add commits and push from the host you're in to github and thenyou manually pull it in VM). Identify the issue locally, if needed execute commands over ssh, commit locally, push, pull from inside the VM, rebuild in the vm, repeat if neccessary

I already started the work on removing and changing stuff. The friend has asus ROG laptop. If you accidentally (so don't go looking for it specifically) bump into it, remove it along the way.

You in the previous session already made some progress and made a few commits. It boots, and I can log in. Note that every time you want to reboot the machine, that the disk is encrypted and you have to give me time to react, and go there and enter the password of disk LUKS!

When calling long-running processes, make sure to redirect the output to some temp file, so that I can connect and read it later!!! THIS INCLUDES REBUILDS!! announce the path to the log file first, then launch the build, or any other long-running command.

Be sure to keep me in the loop, ask me questions on every decision branch. DO NOT FUCKING RUMINATE!! JUST ASK QUICKLY WITHOUT FUCKING LOOPS TO TRY TO GUESS WHAT I MEANT!!! IF I'M WRONG ABOUT MY APPROACH SAY SO! Ask me for clarifications! But if it involves doing anything right inside the virtual machine, feel free to do anything you want without any hesitation to check your hypothese or make experiments. The VM is purely for tests, kill, burn, delete, create anything you want in it, as long as it is generally flows throught the git flow I described earlier.

Your current task is installing into the current VM through nix config the following software: pass-wayland (the unix password manager), anytype, btrfs assistant, gparted, Oh My Pi (has https://github.com/can1357/oh-my-pi/blob/main/flake.nix). Make sure when installing stuff, that is uses the same nixpkgs that the main profile uses. I don't want to have a lot of nixpkgs versions in parallel, especially regarding omp. You already made a commit with most of the work (e014cdd3aaf31805e59da9952580bc4284f80cc0)

Your last attempt at rebuild switch failed with this:
```
building '/nix/store/4436iwap1kv4089hzki3z4adq2lhf0ql-activate.drv'...
building '/nix/store/r4bhy0sql24bcjq9dfc9x9rg8994biml-activate.drv'...
building '/nix/store/4ysyw31y90sks4vmqp8cp7m4b9013lds-nixos-system-xiaomi-A35S-laptop-nixos-26.11.20260723.e2587ca.drv'...
building '/nix/store/bb05w7grf7hvpqx2g66i8az2xvxwvizm-nixos-system-xiaomi-A35S-laptop-nixos-26.11.20260723.e2587ca.drv'...
warning: /root/.nix-defexpr/channels exists, but channels have been disabled.
warning: /nix/var/nix/profiles/per-user/root/channels exists, but channels have been disabled.
warning: /root/.nix-defexpr/channels exists, but channels have been disabled.
Due to https://github.com/NixOS/nix/issues/9574, Nix may still use these channels when NIX_PATH is unset.
Delete the above directory or directories to prevent this.
Checking switch inhibitors... done
Skipping "/efi/EFI/systemd/systemd-bootx64.efi", same boot loader version in place already.
Skipping "/efi/EFI/BOOT/BOOTX64.EFI", same boot loader version in place already.
stopping the following units: accounts-daemon.service, polkit.service
activating the configuration...
setting up /etc...
reloading user units for gdm-greeter...
reloading the following user units: dbus-broker.service
restarting the following user units: nixos-activation.service
reloading user units for root...
reloading the following user units: dbus-broker.service
restarting the following user units: nixos-activation.service
restarting sysinit-reactivation.target
reloading the following units: dbus-broker.service
restarting the following units: home-manager-evadev.service, nix-daemon.service
starting the following units: accounts-daemon.service, polkit.service
Failed to restart home-manager-evadev.service
the following new units were started: libvirtd.service, NetworkManager-dispatcher.service
warning: the following units failed: home-manager-evadev.service
× home-manager-evadev.service - Home Manager environment for evadev
     Loaded: loaded (/etc/systemd/system/home-manager-evadev.service; enabled; preset: ignored)
     Active: failed (Result: exit-code) since Wed 2026-08-19 18:49:49 MSK; 263ms ago
   Duration: 1h 33min 48.091s
 Invocation: 3b6840c0e693450eac502652bcfe88a5
    Process: 90276 ExecStart=/nix/store/jy0abkqvcnv63m7skj6ak06m0sv3sbks-hm-setup-env /nix/store/p5dqf6bsn1c6b494ypnwr9xjm0nygzf0-home-manager-generation (code=exited, status=1/FAILURE)
   Main PID: 90276 (code=exited, status=1/FAILURE)
         IP: 0B in, 0B out
         IO: 0B read, 0B written
   Mem peak: 32.9M
        CPU: 2.390s

Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[91130]: dbus-daemon[91130]: [session uid=1000 pid=91130 pidfd=5] Successfully activated service 'ca.desrt.dconf'
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[90276]: Activating disableDiscordUpdates
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[90276]: Activating fixDiscordModules
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[90276]: Activating nixcord-vencord-settings
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[90276]: Activating notifyQtColorChange
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[91155]: Error connecting: Cannot autolaunch D-Bus without X11 $DISPLAY
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Main process exited, code=exited, status=1/FAILURE
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Failed with result 'exit-code'.
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos systemd[1]: Failed to start Home Manager environment for evadev.
Aug 19 18:49:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Consumed 2.390s CPU time over 2.357s wall clock time, 32.9M memory peak.
Command 'systemd-run -E LOCALE_ARCHIVE -E NIXOS_INSTALL_BOOTLOADER -E NIXOS_NO_CHECK --collect --no-ask-password --pipe --quiet --service-type=exec --unit=nixos-rebuild-switch-to-configuration /nix/store/2kqpqbp4h1z0pm8zfbwm1qd1hgkdic4w-nixos-system-xiaomi-A35S-laptop-nixos-26.11.20260723.e2587ca/bin/switch-to-configuration switch' returned non-zero exit status 4.
EXIT_CODE=4
```

And after I tried rebooting and logging in, it says that niri config is wrong (has impromer syntax) and needs validation. One of the earlier things we did is we tried messing with the video device of the machine. We tried increasing the resolution and enabling more hardware acceleration. These changes might partly be gone after a restart and potentially because I relaunched the VM, and the virtual manager gui might overrode something in the vm config. or not. I don't know. Investigate this
