pkgs: {
  name = "qemu-private-store-mount-grep";

  hostPkgs = pkgs;

  nodes = {
    shared = _: { };
    private = _: { imports = [ ../modules/qemu-vm-isolation.nix ]; };
    useNixStoreImage = {
      virtualisation = {
        sharedDirectories = pkgs.lib.mkForce { };
        useNixStoreImage = true;
      };
    };
  };

  testScript = ''
    start_all()
    shared.wait_for_unit("multi-user.target")
    private.wait_for_unit("multi-user.target")
    useNixStoreImage.wait_for_unit("multi-user.target")

    shared.succeed("[[ $(mount | grep -c virt) -gt 0 ]]")
    private.succeed("[[ $(mount | grep -c virt) -eq 0 ]]")
    useNixStoreImage.succeed("[[ $(mount | grep -c virt) -eq 0 ]]")

    shared.succeed("[[ -e ${pkgs.pv} ]]")
    private.fail("[[ -e ${pkgs.pv} ]]")

    # useNixStoreImage isn't ready until this works:
    # useNixStoreImage.fail("[[ -e ${pkgs.pv} ]]")
  '';
}
