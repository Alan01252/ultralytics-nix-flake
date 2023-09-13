{
  description = "Application packaged using poetry2nix";
   
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  inputs.poetry2nix = {
    url = "github:K900/poetry2nix/new-bootstrap-fixes";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, poetry2nix }:
    let
      systems = [ "x86_64-linux" ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ poetry2nix.overlay ];
          };

          poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            python = pkgs.python311;
         };
        in
        {
          default = pkgs.mkShell {
            buildInputs = with pkgs; [
              poetryEnv
            ];
          };
        });

    };
}

