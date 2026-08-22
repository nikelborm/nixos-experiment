let
  espPartition = {
    priority = 1;
    name = "ESP";
    start = "1M";
    end = "4G"; # room for per-btrfs-snapshot UKI generations
    type = "EF00";
    content = {
      type = "filesystem";
      format = "vfat";
      mountpoint = "/efi";
      mountOptions = [ "umask=0077" ];
    };
  };

  btrfsBaseOpts = [
    "noatime"
    # stated these explicitly rather than relying on btrfs auto-detection: the
    # filesystem sits on top of a LUKS+LVM device-mapper stack, where the
    # underlying `rotational` flag does not always propagate, so we don't want
    # btrfs guessing wrong.
    "ssd"
    "space_cache=v2"
  ];
  btrfsCompressOpts = btrfsBaseOpts ++ [ "compress=zstd:11" ];
  btrfsNoCompressOpts = btrfsBaseOpts ++ [ "compress=none" ];


  # Very important detail I learned recently is that when mounting many different
  # subvolumes from the same device, the compress option of the first subvolume
  # applies to the whole filesystem and all other mounted subvolumes, so I need
  # to call `btrfs property set` manually to actually control this the way I want

  # Also another important detail for chattr: lowercase c is compression,
  # uppercase C is nocow
  rootSubvolumes = builtins.listToAttrs (
    map mkSubvol [
      # btrfs property set ./@/ compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@
      "/"

      # mkdir -p ./@/home
      # btrfs property set ./@/home compression zstd
      # btrfs property set ./@home compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@home
      "/home"

      # mkdir -p ./@home/evadev/.cache
      # chattr +C ./@home_evadev_.cache ./@home/evadev/.cache
      # chown -R 1000:1000 ./@home_evadev_.cache ./@home/evadev
      # btrfs filesystem defragment -r -f --nocomp ./@home_evadev_.cache
      {
        #! nocow, because has writes often and doesn't compress well (compression
        #! is not supported with nocow) a separate partition to exclude from snapshots
        mountpoint = "/home/evadev/.cache";
        options = btrfsNoCompressOpts ++ [ "nofail" ];
      }

      # mkdir -p ./@home/evadev/.vagrant.d/boxes
      # btrfs property set ./@home_evadev_.vagrant.d_boxes compression zstd
      # btrfs property set ./@home/evadev/.vagrant.d/boxes compression zstd
      # touch ./@home_evadev_.vagrant.d_boxes/.gitkeep
      # chown -R 1000:1000 ./@home_evadev_.vagrant.d_boxes ./@home/evadev/.vagrant.d
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@home_evadev_.vagrant.d_boxes
      {
        mountpoint = "/home/evadev/.vagrant.d/boxes";
        #! no point in making it nocow, because live images live elsewhere
        #! and we can also compress base images
        options = btrfsCompressOpts ++ [ "nofail" ];
      }

      # mkdir -p ./@/var/lib/libvirt/qemu/save
      # btrfs property set ./@var_lib_libvirt_qemu_save compression zstd
      # btrfs property set ./@/var/lib/libvirt/qemu/save compression zstd
      # chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_save ./@/var/lib/libvirt/qemu/save
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_save
      "/var/lib/libvirt/qemu/save"

      # mkdir -p ./@/var/lib/libvirt/qemu/dump
      # btrfs property set ./@var_lib_libvirt_qemu_dump compression zstd
      # btrfs property set ./@/var/lib/libvirt/qemu/dump compression zstd
      # chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_dump ./@/var/lib/libvirt/qemu/dump
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_dump
      "/var/lib/libvirt/qemu/dump"

      # mkdir -p ./@/var/lib/libvirt/qemu/ram
      # btrfs property set ./@var_lib_libvirt_qemu_ram compression zstd
      # btrfs property set ./@/var/lib/libvirt/qemu/ram compression zstd
      # chown libvirt-qemu:libvirt-qemu ./@var_lib_libvirt_qemu_ram ./@/var/lib/libvirt/qemu/ram
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_qemu_ram
      "/var/lib/libvirt/qemu/ram"

      # mkdir -p ./@/var/lib/libvirt/images
      # chattr +C ./@var_lib_libvirt_images ./@/var/lib/libvirt/images
      # chmod ug+x ./@var_lib_libvirt_images ./@/var/lib/libvirt/images
      # chown root:libvirt ./@var_lib_libvirt_images ./@/var/lib/libvirt/images
      # btrfs filesystem defragment -r -f --nocomp ./@var_lib_libvirt_images
      {
        #! nocow on images because it has heavy random-like updates
        #! mount without compression, because nocow doesn't support it
        mountpoint = "/var/lib/libvirt/images";
        options = btrfsNoCompressOpts;
      }

      #! sticky bit so that people can freely add images and it will get libvirt
      #! group instead of file creator group

      # mkdir -p ./@/var/lib/libvirt/boot
      # btrfs property set ./@var_lib_libvirt_boot compression zstd
      # btrfs property set ./@/var/lib/libvirt/boot compression zstd
      # chmod g+s ./@var_lib_libvirt_boot ./@/var/lib/libvirt/boot
      # chown root:libvirt ./@var_lib_libvirt_boot ./@/var/lib/libvirt/boot
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_libvirt_boot
      "/var/lib/libvirt/boot"

      # mkdir -p ./@/var/lib/ollama
      # chown ollama:ollama ./@var_lib_ollama ./@/var/lib/ollama
      # mkdir -p ./@/var/lib/ollama/.cache
      # chattr +C ./@/var/lib/ollama/.cache
      # btrfs property set ./@var_lib_ollama compression none
      # btrfs property set ./@/var/lib/ollama compression none
      # mkdir -p ./@var_lib_ollama/blobs
      # btrfs filesystem defragment -r -f --nocomp ./@var_lib_ollama
      {
        mountpoint = "/var/lib/ollama";
        options = btrfsNoCompressOpts;
      }

      # mkdir -p ./@/var/lib/docker
      # btrfs property set ./@var_lib_docker compression zstd
      # btrfs property set ./@/var/lib/docker compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_docker
      "/var/lib/docker"

      # mkdir -p ./@/var/lib/containers
      # btrfs property set ./@var_lib_containers compression zstd
      # btrfs property set ./@/var/lib/containers compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_containers
      "/var/lib/containers"

      # mkdir -p ./@/var/lib/containerd
      # btrfs property set ./@var_lib_containerd compression zstd
      # btrfs property set ./@/var/lib/containerd compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_containerd
      "/var/lib/containerd"

      # mkdir -p ./@/var/lib/rancher
      # btrfs property set ./@var_lib_rancher compression zstd
      # btrfs property set ./@/var/lib/rancher compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_rancher
      "/var/lib/rancher"

      # mkdir -p ./@/var/lib/kubelet
      # btrfs property set ./@var_lib_kubelet compression zstd
      # btrfs property set ./@/var/lib/kubelet compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@var_lib_kubelet
      "/var/lib/kubelet"

      # mkdir -p ./@/big_media
      # chown -R 1000:1000 ./@big_media ./@/big_media
      # chmod +rwx ./@big_media ./@/big_media
      # btrfs property set ./@big_media compression zstd
      # btrfs property set ./@/big_media compression zstd
      # btrfs filesystem defragment -r -f -czstd -L 15 ./@big_media
      "/big_media"

      # mkdir -p ./@/var/cache
      # chattr +C ./@var_cache ./@/var/cache
      # btrfs filesystem defragment -r -f --nocomp ./@var_cache
      {
        mountpoint = "/var/cache";
        options = btrfsNoCompressOpts;
      }

      # mkdir -p ./@/var/log
      # chattr +C ./@var_log ./@/var/log
      # btrfs filesystem defragment -r -f --nocomp ./@var_log
      {
        mountpoint = "/var/log";
        options = btrfsNoCompressOpts;
      }

      # mkdir -p ./@/var/tmp
      # chattr +C ./@var_tmp ./@/var/tmp
      # chmod +t ./@var_tmp ./@/var/tmp
      # btrfs filesystem defragment -r -f --nocomp ./@var_tmp
      {
        mountpoint = "/var/tmp";
        options = btrfsNoCompressOpts;
      }
    ]
  );

  luksPartition = {
    size = "100%";
    content = {
      type = "luks";
      name = "crypted";
      content = {
        type = "lvm_pv";
        vg = "pool";
      };

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
    };
  };

  mkSubvol =
    entry:
    let
      mountpoint = if builtins.isString entry then entry else entry.mountpoint;
      # Drop the leading "/" (substring from index 1); "/" itself becomes "".
      relative = builtins.substring 1 (builtins.stringLength mountpoint) mountpoint;
    in
    {
      name = "/@${builtins.replaceStrings [ "/" ] [ "_" ] relative}";
      value = {
        inherit mountpoint;
        mountOptions = if builtins.isString entry then btrfsCompressOpts else entry.options;
      };
    };
in
{
  disko.devices = {
    disk.main = {
      # For the real install, prefer a stable path, e.g.
      # - /dev/disk/by-id/nvme-SAMSUNG_MZVLQ512HBLU-00B00_S6F5NJ0R764519
      #
      # For testing these are fine
      # - /dev/vda (VMs)
      # - /dev/nvme0n1
      device = "/dev/vda";
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
          size = "2G";
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
            # Override existing filesystem, and choose xxhash which will catch
            # errors with greater chance. Single encrypted bit flip causes 128-bit
            # flip on decrypted side. This makes crc32c property of being certain
            # to catch 100% of errors on single-bit flip usecases to disappear
            # and become probabilistic 2⁻³². And since we're already on a
            # non-deterministic zone, better to choose the algorithm that has
            # stronger collision resistance
            extraArgs = [ "--force" "--checksum" "xxhash" ];
            subvolumes = rootSubvolumes;
          };
        };
      };
    };
  };
}
