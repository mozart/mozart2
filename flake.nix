{
  inputs.nixpkgs.url = "nixpkgs-22.05";

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      targetPackages = with pkgs; [ cmake scala sbt ];
    }
  }
}
