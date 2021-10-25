{ config, lib, modulesPath, pkgs, ... }:
let
  inherit (lib) findSingle mkForce mkVMOverride;

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
      storeContents = config.virtualisation.pathsInNixDB;
    };

  virtualisation = {

    # This should be the default.
    bootDevice = lookupDriveDeviceName "root" config.virtualisation.qemu.drives;

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
