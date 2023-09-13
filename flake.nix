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
            config.allowUnfree = true;
            overlays = [ poetry2nix.overlay ];
          };

          poetryEnv = pkgs.poetry2nix.mkPoetryEnv {
            projectDir = ./.;
            python = pkgs.python311;
            overrides = pkgs.poetry2nix.overrides.withDefaults (self: super: {


	      ultralytics = super.ultralytics.overridePythonAttrs (
                old: {
                  nativeBuildInputs = [ pkgs.cudaPackages.cudatoolkit pkgs.cudaPackages.libcurand ] ++ old.nativeBuildInputs;
                  buildInputs = (old.buildInputs or [ ]) ++ [ super.setuptools ];
                }
              );



              opencv-python = super.opencv-python.overridePythonAttrs (

                old: {
			preBuild = ''
			   echo "hi everybody"
                           ls -ltrh
			   cat > cv2/version.py <<EOF
opencv_version = "${old.version}"
contrib = False
headless = False
rolling = False
ci_build = False
EOF

                          sed -i 's/\[ r"python\/cv2\/py.typed" \] if sys.version_info >= (3, 6) else \[\]/[]/' ./setup.py
                          sed -i 's/rearrange_cmake_output_data\["cv2.typing"\] = \["python\/cv2" + r"\/typing\/.*\\.py"\]/    pass/' ./setup.py
                          cat setup.py
'';
                }
              );
          });
        };
        in
        {
          default = pkgs.mkShell {

            buildInputs = with pkgs; [
              poetryEnv
              cudaPackages.cudatoolkit
              cudaPackages.cuda_cudart
              cudaPackages.libcurand.lib
              cudaPackages.cudnn
              cudaPackages.cuda_cupti
              cudaPackages.nccl
              python311Packages.setuptools
            ];
          };
        });

    };
}

