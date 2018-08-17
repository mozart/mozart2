
with import <nixpkgs> {
  overlays = [ (import ./mozart-overlay.nix) ];
};

pkgs.mozart2
