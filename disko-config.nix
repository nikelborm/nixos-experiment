{
  disko.devices = {
    disk.main = {
      # device = "/dev/sda";
      type = "disk";
      content = {
        type = "gpt";
        partitions = {
          ESP = {
            priority = 1;
            name = "ESP";
            start = "1M";
            end = "512M";
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
        root = {
          size = "100%";
          content = {
            type = "filesystem";
            format = "btrfs";
            extraArgs = [ "-f" ]; # Override existing partition
            # not sure if it's possible to apply it when /@ should be mounted before /partition-root
            # mountpoint = "/partition-root";
            # mountOptions = [
            #   "defaults"
            # ];
            subvolumes = {
              "/@" = {
                mountpoint = "/";
              };
              "/@home" = {
                # mountOptions = [ "compress=zstd" ];
                mountpoint = "/home";
              };
            };
          };
        };
        swap = {
          size = "100%";
          content = {
            type = "swap";
            priority = 0;
            discardPolicy = "both";
            randomEncryption = false;
            resumeDevice = false;
          };
        };
      };
    };
  };
}
