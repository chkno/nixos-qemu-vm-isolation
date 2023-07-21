pkgs: {
  name = "qemu-private-store-mount-grep";

  hostPkgs = pkgs;

  includeTestScriptReferences = false;

  nodes = {
    shared = _: { };
    private = _: { imports = [ ../modules/qemu-vm-isolation.nix ]; };
    privateErofs = _: {
      imports = [ ../modules/qemu-vm-isolation.nix ];
      virtualisation.qemu.isolation.nixStoreFilesystemType = "erofs";
    };
    privateSquash = _: {
      imports = [ ../modules/qemu-vm-isolation.nix ];
      virtualisation.qemu.isolation.nixStoreFilesystemType = "squashfs";
    };
    useNixStoreImage = {
      virtualisation = {
        sharedDirectories = pkgs.lib.mkForce { };
        useNixStoreImage = true;
      };
    };
  };

  testScript = ''
    start_all()
    for machine in [shared, private, privateErofs, privateSquash, useNixStoreImage]:
      machine.wait_for_unit("multi-user.target")

    shared.succeed("[[ $(mount | grep -c virt) -gt 0 ]]")
    shared.succeed("[[ -e ${pkgs.pv} ]]")

    for machine in [private, privateErofs, privateSquash, useNixStoreImage]:
      machine.succeed("[[ $(mount | grep -c virt) -eq 0 ]]")
      machine.fail("[[ -e ${pkgs.pv} ]]")
  '';
}
