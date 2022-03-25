{ sources ? import ./nix/sources.nix }:
let
  nixpkgs = import sources.nixpkgs { };
  unstable = import sources.unstable { };
in
nixpkgs.mkShell {
    name = "node";
    buildInputs = with nixpkgs; [
        unstable.nodejs-16_x
        niv
        unstable.vscodium
    ];
    shellHook = ''
      export PATH="$PWD/node_modules/.bin/:$PATH"
    '';
}

