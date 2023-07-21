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

  boot.initrd.availableKernelModules = [ "squashfs" ];

  fileSystems = mkVMOverride {
    "${storeMountPath}" = {
      device =
        lookupDriveDeviceName "nixstore" config.virtualisation.qemu.drives;
      fsType = "squashfs";
      options = [ "ro" ];
      neededForBoot = true;
    };
  };

  system.build.squashfsStore =
    pkgs.callPackage (modulesPath + "/../lib/make-squashfs.nix") {
      storeContents = config.virtualisation.additionalPaths;
    };

  virtualisation = {

    sharedDirectories = mkForce { };

    qemu.drives = [{
      name = "nixstore";
      file = "${config.system.build.squashfsStore}";
      driveExtraOpts = {
        format = "raw";
        read-only = "on";
        werror = "report";
      };
    }];

  };
}
