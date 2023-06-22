{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs?ref=nixos-unstable";
  outputs = { self, nixpkgs, }:
    let
      inherit (nixpkgs.lib) genAttrs;

      systems = import ./lib/tier1.nix nixpkgs;

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
