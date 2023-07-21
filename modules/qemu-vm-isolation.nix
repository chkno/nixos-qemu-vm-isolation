{ config, lib, modulesPath, pkgs, ... }:
let
  inherit (lib)
    escapeShellArg findSingle mkForce mkIf mkMerge mkOption mkVMOverride
    optional;

  cfg = config.virtualisation.qemu.isolation;

  lookupDriveDeviceName = driveName: driveList:
    (findSingle (drive: drive.name == driveName)
      (throw "Drive ${driveName} not found")
      (throw "Multiple drives named ${driveName}") driveList).device;

  storeMountPath = if config.virtualisation.writableStore then
    "/nix/.ro-store"
  else
    "/nix/store";

  hostPkgs = config.virtualisation.host.pkgs;

  storeContents =
    hostPkgs.closureInfo { rootPaths = config.virtualisation.additionalPaths; };

  nixStoreImages = {
    ext4 = import (modulesPath + "/../lib/make-disk-image.nix") {
      inherit pkgs config lib;
      additionalPaths = [ storeContents ];
      onlyNixStore = true;
      label = "nix-store";
      partitionTableType = "none";
      installBootLoader = false;
      diskSize = "auto";
      additionalSpace = "0M";
      copyChannel = false;
    };
    erofs = hostPkgs.runCommand "nix-store-image" { } ''
      mkdir $out
      cd ${builtins.storeDir}
      ${hostPkgs.erofs-utils}/bin/mkfs.erofs \
        --force-uid=0 \
        --force-gid=0 \
        -L nix-store \
        -U eb176051-bd15-49b7-9e6b-462e0b467019 \
        -T 0 \
        --exclude-regex="$(
          <${storeContents}/store-paths \
            sed -e 's^.*/^^g' \
          | cut -c -10 \
          | ${hostPkgs.python3}/bin/python -c ${
            escapeShellArg (builtins.readFile
              (modulesPath + "/virtualisation/includes-to-excludes.py"))
          } )" \
        $out/nixos.img \
        .
    '';
  };

in {
  options = {
    virtualisation.qemu.isolation.nixStoreFilesystemType = mkOption {
      description = ''
        What filesystem to use for the guest's Nix store.

        erofs is more compact than ext4, but less mature.
      '';
      type = lib.types.enum [ "ext4" "erofs" ];
      default = "ext4";
    };
  };
  config = mkMerge [
    {
      boot.initrd.kernelModules =
        optional (cfg.nixStoreFilesystemType == "erofs") "erofs";

      fileSystems = mkVMOverride {
        "${storeMountPath}" = {
          device =
            lookupDriveDeviceName "nixstore" config.virtualisation.qemu.drives;
          fsType = cfg.nixStoreFilesystemType;
          options = [ "ro" ];
          neededForBoot = true;
        };
      };

      system.build.nixStoreImage =
        nixStoreImages."${cfg.nixStoreFilesystemType}";

      virtualisation = {

        sharedDirectories = mkForce { };

        qemu.drives = [{
          name = "nixstore";
          file = "${config.system.build.nixStoreImage}/nixos.img";
          driveExtraOpts = {
            format = "raw";
            read-only = "on";
            werror = "report";
          };
        }];

      };
    }
    (mkIf (cfg.nixStoreFilesystemType == "ext4") {
      # We use this to disable fsck runs on the ext4 nix store image because stage-1
      # fsck crashes (maybe because the device is read-only?), halting boot.
      boot.initrd.checkJournalingFS = false;
    })
  ];
}
