{
  outputs = { self, nixpkgs, }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = nixpkgs.lib.systems.supported.tier1;

      forAllSystems = genAttrs systems;

    in {
      nixosModules = {
        qemu-vm-isolation = import ./modules/qemu-vm-isolation.nix;
      };
      checks = forAllSystems (system: {
        mount-grep = nixpkgs.legacyPackages."${system}".nixosTest
          (import ./checks/mount-grep.nix);
      });
    };
}
