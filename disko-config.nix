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
        partitions = {
          ESP = {
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

          luks = {
            size = "100%";
            content = {
              type = "luks";
              name = "crypted";
              # extraOpenArgs = [ ];
              settings = {
                # if you want to use the key for interactive login be sure there is no trailing newline
                # for example use `echo -n "password" > /tmp/secret.key`
                # keyFile = "/tmp/secret.key";
                allowDiscards = true;
              };
              # additionalKeyFiles = [ "/tmp/additionalSecret.key" ];
              passwordFile = "/tmp/secret.key";
              content = {
                type = "lvm_pv";
                vg = "pool";
              };
            };
          };
        };
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
            subvolumes = {
              "/@" = {
                mountpoint = "/";
                mountOptions = btrfsOpts;
              };
              "/@home" = {
                mountpoint = "/home";
                mountOptions = btrfsOpts;
              };
              "/@home_nikel_.vagrant.d_boxes" = {
                mountpoint = "/home/nikel/.vagrant.d/boxes";
                mountOptions = btrfsOpts ++ [ "nofail" ];
              };
              "/@var_lib_libvirt_qemu_save" = {
                mountpoint = "/var/lib/libvirt/qemu/save";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_libvirt_qemu_dump" = {
                mountpoint = "/var/lib/libvirt/qemu/dump";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_libvirt_qemu_ram" = {
                mountpoint = "/var/lib/libvirt/qemu/ram";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_libvirt_images" = {
                mountpoint = "/var/lib/libvirt/images";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_libvirt_boot" = {
                mountpoint = "/var/lib/libvirt/boot";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_ollama" = {
                mountpoint = "/var/lib/ollama";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_docker" = {
                mountpoint = "/var/lib/docker";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_rancher" = {
                mountpoint = "/var/lib/rancher";
                mountOptions = btrfsOpts;
              };
              "/@var_lib_kubelet" = {
                mountpoint = "/var/lib/kubelet";
                mountOptions = btrfsOpts;
              };
              "/@big_media" = {
                mountpoint = "/big_media";
                mountOptions = btrfsOpts;
              };
              "/@var_cache" = {
                mountpoint = "/var/cache";
                mountOptions = btrfsOpts;
              };
              "/@var_log" = {
                mountpoint = "/var/log";
                mountOptions = btrfsOpts;
              };
              "/@var_tmp" = {
                mountpoint = "/var/tmp";
                mountOptions = btrfsOpts;
              };
            };
          };
        };
      };
    };
  };
}
