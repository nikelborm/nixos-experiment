let
  # Common btrfs mount options for every subvolume.
  # `ssd` and `space_cache=v2` are stated explicitly rather than relying on
  # btrfs auto-detection: the filesystem sits on top of a LUKS+LVM
  # device-mapper stack, where the underlying `rotational` flag does not
  # always propagate, so we don't want btrfs guessing wrong.
  btrfsOpts = [
    "noatime"
    "compress=zstd"
    "ssd"
    "space_cache=v2"
  ];

  # Build a btrfs subvolume entry, following our naming convention: the
  # subvolume is named after the mountpoint with the leading slash dropped,
  # every remaining slash turned into an underscore, and an `@` prefix (so
  # `/var/lib/docker` -> `@var_lib_docker`, and `/` -> `@`).
  #
  # The argument is either a bare mountpoint string, or a
  # `{ mountpoint; extraOptions; }` attrset when extra mount options are needed
  # (both fields required in that form). Any `extraOptions` are appended to the
  # shared `btrfsOpts` (e.g. a `nofail` for a mountpoint that may not always be
  # present).
  #
  # Returns a `{ name; value; }` pair for `builtins.listToAttrs`, where the
  # attribute name is the disko subvolume key (`/@…`).
  mkSubvol =
    entry:
    let
      mountpoint = if builtins.isString entry then entry else entry.mountpoint;
      extraOptions = if builtins.isString entry then [ ] else entry.extraOptions;
      # Drop the leading "/" (substring from index 1); "/" itself becomes "".
      relative = builtins.substring 1 (builtins.stringLength mountpoint) mountpoint;
      subvol = "@" + builtins.replaceStrings [ "/" ] [ "_" ] relative;
    in
    {
      name = "/${subvol}";
      value = {
        inherit mountpoint;
        mountOptions = btrfsOpts ++ extraOptions;
      };
    };

  # ESP - the EFI system partition, mounted at /boot.
  espPartition = {
    priority = 1;
    name = "ESP";
    start = "1M";
    end = "1G"; # 1G, matches the old /boot size; room for many generations
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/boot";
      mountOptions = [ "umask=0077" ];
    };
  };

  # LUKS partition - fills the rest of the disk and holds the LVM PV.
  luksPartition = {
    size = "100%";
    content = {
      type = "luks";
      name = "crypted";

      # ---------------------------------------------------------------
      # LUKS2 format parameters. Baked in permanently at `luksFormat`
      # time (during disko's `format` stage); changing them later needs
      # a full re-encrypt.
      # ---------------------------------------------------------------
      extraFormatArgs = [
        "--type luks2" # LUKS2 header required for TPM2 + recovery tokens
        "--pbkdf argon2id" # memory-hard KDF (LUKS2 default; fine with systemd-boot)
        # 4K crypto sector: matches btrfs/swap/LVM, which all write in >=4K
        # aligned units, so no read-modify-write. 512/1024/2048/4096 are the
        # ONLY legal values (4096 is the max) - correct even though this NVMe
        # advertises 512-byte LBAs and offers no 4K namespace format.
        "--sector-size 4096"
      ];

      settings = {
        allowDiscards = true; # let TRIM reach the SSD (minor metadata leak; standard on NVMe)
        bypassWorkqueues = true; # dm-crypt perf flag - throughput win on fast NVMe

        # Ask the initrd to TRY the TPM2 token at every boot. Harmless
        # while no TPM2 slot exists yet (it just falls through to the
        # passphrase prompt); once you enroll TPM2 (see below) boot starts
        # asking for the TPM2 PIN automatically. Requires systemd stage-1
        # initrd -> boot.initrd.systemd.enable = true in configuration.nix.
        crypttabExtraOpts = [ "tpm2-device=auto" ];
      };

      # ================================================================
      # KEYSLOT #1 - BOOTSTRAP PASSPHRASE  (set automatically by disko)
      # ================================================================
      # Put your chosen passphrase into this file *before* running disko.
      # On the live installer /tmp is tmpfs, so it disappears on reboot.
      # Write it WITHOUT leaking the secret into shell history: read it
      # interactively, then printf it into the file (no trailing newline):
      #
      #     read -rs -p "LUKS passphrase: " pw; echo
      #     printf %s "$pw" > /tmp/secret.key; unset pw
      #
      # disko's `format` stage runs `cryptsetup luksFormat` with this file,
      # creating keyslot 0. This passphrase is only a bootstrap: after
      # TPM2+PIN and the recovery key are enrolled AND verified, you delete
      # this slot (see "REMOVE THE PASSPHRASE" below).
      passwordFile = "/tmp/secret.key";

      # ================================================================
      # KEYSLOT #2 - RECOVERY KEY  (generated automatically by disko)
      # ================================================================
      #   HOW:   with this set to true, disko's `format` stage also runs
      #          `systemd-cryptenroll --recovery-key`, enrolling a
      #          high-entropy, keyboard-layout-independent passphrase into
      #          its own keyslot (token type "systemd-recovery").
      #   WHEN:  during the disko *format* stage, right after keyslot 0 is
      #          created (i.e. while `apply-disko.sh` is running).
      #   WHERE: NOT a file. The recovery key is printed to the TERMINAL as
      #          plain text AND a QR code, then disko PAUSES on "Press Enter
      #          when you scanned the QR code...". Photograph the QR / copy
      #          the text and write it on paper NOW - it is shown only once.
      #          This slot is what lets you open the disk on ANY other
      #          machine (`cryptsetup luksOpen`), since it needs no TPM.
      enrollRecovery = true;

      # ================================================================
      # KEYSLOT #3 - TPM2 + PIN  (NOT done by disko - you run this once,
      #                           from the running installed system)
      # ================================================================
      # disko has no native TPM2 enrollment, so this is a manual one-time
      # step after first boot. It binds a keyslot to THIS machine's TPM,
      # released only when the correct PIN is entered => unlocking needs
      # BOTH the chip present AND the PIN.
      #
      # Confirm the LUKS partition first (ESP is p1, so LUKS is p2):
      #     lsblk -o NAME,SIZE,FSTYPE /dev/nvme0n1
      #
      # Run it fully interactively so NO secret ever lands in shell history
      # or on disk - systemd-cryptenroll prompts for the current passphrase
      # (to authorize) and for the new PIN (with confirmation):
      #
      #     sudo systemd-cryptenroll \
      #       --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs="" \
      #       /dev/nvme0n1p2
      #
      # To pre-feed the PIN instead of being prompted (e.g. to reuse it for
      # the PCR 7 re-enroll later), read it with `read -s` and pass it via
      # the $NEWPIN env var - never as a literal argument (systemd >= 255;
      # this box runs systemd 261). Become root first so sudo can't strip
      # the env var:
      #
      #     sudo -i
      #     read -rs -p "New TPM2 PIN: " NEWPIN; echo; export NEWPIN
      #     systemd-cryptenroll --tpm2-device=auto --tpm2-with-pin=yes \
      #       --tpm2-pcrs="" /dev/nvme0n1p2   # still prompts for the passphrase
      #     unset NEWPIN; exit
      #
      # --tpm2-pcrs="" = NO PCR binding = the NON-Secure-Boot option: robust
      # (survives firmware/kernel updates), protected by the PIN plus the
      # TPM's hardware anti-hammering lockout.
      #
      # ---- VERIFY BEFORE YOU TRUST IT -------------------------------
      # REBOOT and confirm the machine unlocks via the TPM - you should be
      # prompted "Please enter TPM2 PIN:" instead of the passphrase. Do NOT
      # skip this: if enrollment or the initrd is wrong, you want keyslot 0
      # still present as a fallback.
      #
      # ---- REMOVE THE PASSPHRASE (only after TPM boot is verified) ---
      # Once TPM+PIN boot works AND the recovery key is safely on paper,
      # delete the bootstrap passphrase so the only ways in are (a) TPM+PIN
      # on this laptop or (b) the paper recovery key:
      #
      #     sudo cryptsetup luksDump /dev/nvme0n1p2    # inspect slots/tokens first
      #     sudo systemd-cryptenroll --wipe-slot=password /dev/nvme0n1p2
      #
      # (--wipe-slot=password removes ONLY plain-passphrase slots; the
      #  recovery and tpm2 slots carry tokens and are left untouched.)
      #
      # ---- LATER: SECURE BOOT -> RE-ENROLL AGAINST PCR 7 ------------
      # After you set up Secure Boot / lanzaboote, PCR 7 changes and the
      # PIN-only TPM slot stops matching. Re-enroll bound to PCR 7 (rewrites
      # only the tiny tpm2 keyslot - your data is untouched):
      #
      #     sudo systemd-cryptenroll --wipe-slot=tpm2 \
      #       --tpm2-device=auto --tpm2-with-pin=yes --tpm2-pcrs="7" \
      #       /dev/nvme0n1p2
      #       # prompts for the passphrase + new PIN interactively, as above
      #
      # Then REBOOT and VERIFY the TPM+PIN unlock again (same check as
      # above) BEFORE relying on it - a wrong PCR set otherwise only shows
      # up at the next boot and forces you onto the recovery key.
      # ================================================================

      content = {
        type = "lvm_pv";
        vg = "pool";
      };
    };
  };

  # Root btrfs subvolumes, one per mountpoint (see `mkSubvol`).
  rootSubvolumes = builtins.listToAttrs (map mkSubvol [
    "/"
    "/home"
    {
      mountpoint = "/home/nikel/.vagrant.d/boxes";
      extraOptions = [ "nofail" ];
    }
    "/var/lib/libvirt/qemu/save"
    "/var/lib/libvirt/qemu/dump"
    "/var/lib/libvirt/qemu/ram"
    "/var/lib/libvirt/images"
    "/var/lib/libvirt/boot"
    "/var/lib/ollama"
    "/var/lib/docker"
    "/var/lib/rancher"
    "/var/lib/kubelet"
    "/big_media"
    "/var/cache"
    "/var/log"
    "/var/tmp"
  ]);
in
{
  disko.devices = {
    disk.main = {
      # For the real install, prefer a stable path, e.g.
      #   /dev/disk/by-id/nvme-SAMSUNG_MZVLQ512HBLU-00B00_<serial>
      # `/dev/nvme0n1` is fine for VM testing.
      device = "/dev/nvme0n1";
      type = "disk";
      content = {
        type = "gpt";
        partitions.ESP = espPartition;
        partitions.luks = luksPartition;
      };
    };

    lvm_vg.pool = {
      type = "lvm_vg";
      lvs = {
        # Fixed-size swap MUST come before the greedy root LV, otherwise a
        # "100%" root would consume the whole VG and leave nothing for swap.
        # 23G matches the old swap partition and is >= RAM for hibernation.
        swap = {
          size = "23G";
          content = {
            type = "swap";
            priority = 0;
            discardPolicy = "both";
            randomEncryption = false; # already encrypted by the LUKS layer below
            resumeDevice = true; # enable hibernation resume from this swap
          };
        };
        root = {
          size = "100%"; # remainder of the VG
          content = {
            type = "btrfs";
            extraArgs = [ "-f" ]; # Override existing filesystem
            subvolumes = rootSubvolumes;
          };
        };
      };
    };
  };
}
