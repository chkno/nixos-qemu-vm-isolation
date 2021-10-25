{ pkgs, ... }: {
  name = "qemu-private-store-mount-grep";

  nodes = {
    shared = _: { };
    private = _: { imports = [ ../modules/qemu-vm-isolation.nix ]; };
  };

  testScript = ''
    start_all()
    shared.wait_for_unit("multi-user.target")
    private.wait_for_unit("multi-user.target")

    shared.succeed("[[ $(mount | grep -c virt) -gt 0 ]]")
    private.succeed("[[ $(mount | grep -c virt) -eq 0 ]]")
  '';
}
