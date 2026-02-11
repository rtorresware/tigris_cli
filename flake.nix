{
  description = "Tigris CLI";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      packageJson = builtins.fromJSON (builtins.readFile ./package.json);
      version = packageJson.version;
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      forAllSystems = nixpkgs.lib.genAttrs systems;
    in
    {
      packages = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
          pname = "tigris-cli";
          tigris-cli = pkgs.buildNpmPackage {
            inherit pname version;
            src = self;
            npmDepsHash = "sha256-LYFLak4oU0Z7v1duS4bAmjA6YI/HNLqhVTBhYHZanMI=";
            nodejs = pkgs.nodejs_20;
            npmBuildScript = "build";
            nativeBuildInputs = [ pkgs.makeWrapper ];
            HUSKY = "0";
            installPhase = ''
              runHook preInstall
              mkdir -p $out/lib/node_modules/${pname}
              cp -r dist package.json README.md node_modules $out/lib/node_modules/${pname}/
              mkdir -p $out/bin
              makeWrapper ${pkgs.nodejs_20}/bin/node $out/bin/tigris \
                --add-flags "$out/lib/node_modules/${pname}/dist/cli.js"
              ln -s $out/bin/tigris $out/bin/t3
              runHook postInstall
            '';
            meta = with pkgs.lib; {
              description = "Command line interface for Tigris object storage";
              homepage = "https://github.com/tigrisdata/cli";
              license = licenses.mit;
              mainProgram = "tigris";
            };
          };
        in
        {
          inherit tigris-cli;
          default = tigris-cli;
        });

      apps = forAllSystems (system:
        let
          pkg = self.packages.${system}.tigris-cli;
        in
        {
          tigris = {
            type = "app";
            program = "${pkg}/bin/tigris";
          };
          t3 = {
            type = "app";
            program = "${pkg}/bin/t3";
          };
          default = {
            type = "app";
            program = "${pkg}/bin/tigris";
          };
        });

      devShells = forAllSystems (system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShell {
            packages = [ pkgs.nodejs_20 pkgs.npm ];
          };
        });
    };
}
