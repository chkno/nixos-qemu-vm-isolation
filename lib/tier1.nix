# Since 168b926435628cb06c4a8cb0f3e6f69f141529f1, we do shenanigans to get the tier1 list.  :(

nixpkgs:

let
  inherit (nixpkgs) lib;
  inherit (lib) elemAt foldl' isList splitString;
  inherit (builtins) readFile;

  lines = splitString "\n";

  between = start: stop: list:
    let
      step = state: x:
        if isNull state && x == start then
          [ ]
        else if isList state then
          if x == stop then { result = state; } else state ++ [ x ]
        else
          state;
    in (foldl' step null list).result;

  strip-quotes = x: elemAt (builtins.match "  \"(.*)\"" x) 0;

  systems-file = "${nixpkgs}/lib/systems/flake-systems.nix";

in map strip-quotes
(between "  # Tier 1" "  # Tier 2" (lines (readFile systems-file)))
