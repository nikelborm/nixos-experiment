I'm trying to compile this config (git cloned into /etc/nixos on the virtual machine) with this command:
git pull; NIX_CONFIG="experimental-features = nix-command flakes pipe-operators" nixos-rebuild switch --flake .

The initial repo is owned by my friend. I'm trying to adopt it to my needs and was in the process of cleanup. Expect to see potentially unnessecary, half/under-cleaned up, or the stuff that was deleted accidentally (over-cleanup) because I didn't realize I would need it later.

The target is a local virtual machine. I want to ensure it works in VM first and only then deploy to my notebook. You have the freedom to run any command inside the VM:
ssh root@192.168.122.35

The ssh command above should just work and you're free to explore the specifics about the environment, the machine, or the config that are wrong. Any modifications to the config MUST be created inside the local folder you're in right now (the branches here and on the vm are same, so you just need to add commits and push from the host you're in to github and thenyou manually pull it in VM). Identify the issue locally, if needed execute commands over ssh, commit locally, push, pull from inside the VM, rebuild in the vm, repeat if neccessary


I already started the work on removing stuff. The friend has asus ROG laptop. If you accidentally (so don't go looking for it specifically) bump into it, remove it along the way.

You in the previous session already made some progress and made a commit. You launched the build, but there were still issues:

When calling long-running processes, make sure to redirect the output to some temp file, so that I can connect and read it later.

The build passes by itself, but I cannot login into the user from the DE (ssh works however).
```
sudo journalctl -u home-manager-evadev.service

Aug 19 16:28:49 xiaomi-A35S-laptop-nixos systemd[1]: Starting Home Manager environment for evadev...
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Starting Home Manager activation
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Activating checkFilesChanged
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Activating checkLinkTargets
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Activating writeBoundary
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Activating linkGeneration
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[980]: Creating home file links in /home/evadev
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos hm-activate-evadev[1296]: ln: failed to create symbolic link '/home/evadev/.cache/.keep': Permission denied
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Main process exited, code=exited, status=1/FAILURE
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Failed with result 'exit-code'.
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos systemd[1]: Failed to start Home Manager environment for evadev.
Aug 19 16:28:49 xiaomi-A35S-laptop-nixos systemd[1]: home-manager-evadev.service: Consumed 263ms CPU time over 487ms wall clock time, 66.4M memory peak, 77.6M read from disk.
```

Identify what went wrong, and continue fixing it in the same cycle I described. Be sure to keep me in the loop, ask me questions on every decision branch. Ask me for clarifications.
