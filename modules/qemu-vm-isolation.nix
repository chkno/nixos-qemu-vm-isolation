{ config, lib, modulesPath, pkgs, ... }:
let
  inherit (lib) findSingle mkForce mkIf mkMerge mkVMOverride;

  lookupDriveDeviceName = driveName: driveList:
    (findSingle (drive: drive.name == driveName)
      (throw "Drive ${driveName} not found")
      (throw "Multiple drives named ${driveName}") driveList).device;

  storeMountPath = if config.virtualisation.writableStore then
    "/nix/.ro-store"
  else
    "/nix/store";

in {

  fileSystems = mkVMOverride {
    "${storeMountPath}" = {
      device =
        lookupDriveDeviceName "nixstore" config.virtualisation.qemu.drives;
      fsType = "ext4";
      options = [ "ro" ];
      neededForBoot = true;
    };
  };

  # We use this to disable fsck runs on the ext4 nix store image because stage-1
  # fsck crashes (maybe because the device is read-only?), halting boot.
  boot.initrd.checkJournalingFS = false;

  system.build.nixStoreImage =
    import (modulesPath + "/../lib/make-disk-image.nix") {
      inherit pkgs config lib;
      additionalPaths = [
        (config.virtualisation.host.pkgs.closureInfo {
          rootPaths = config.virtualisation.additionalPaths;
        })
      ];
      onlyNixStore = true;
      label = "nix-store";
      partitionTableType = "none";
      installBootLoader = false;
      diskSize = "auto";
      additionalSpace = "0M";
      copyChannel = false;
    };

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
