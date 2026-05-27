{
	description = "rust + python devenv";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		flake-utils.url = "github:numtide/flake-utils";

		fenix = {
			url = "github:nix-community/fenix";
			inputs.nixpkgs.follows = "nixpkgs";
		};

		crane.url = "github:ipetkov/crane";
	};

	outputs = { self, nixpkgs, flake-utils, fenix, crane, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				pkgs = import nixpkgs { inherit system; };

				tc = fenix.packages.${system}.stable;
				toolchain = tc.withComponents [
					"cargo"
					"clippy"
					"rust-src"
					"rustc"
					"rustfmt"
					"rust-analyzer"
				];

				craneLib = (crane.mkLib pkgs).overrideToolchain toolchain;
				src = craneLib.cleanCargoSource ./.;
				commonArgs = {
					inherit src;
					strictDeps = true;
				};

				cargoArtifacts = craneLib.buildDepsOnly commonArgs;
				crate = craneLib.buildPackage (commonArgs // { inherit cargoArtifacts; });

			in {
				devShells.default = pkgs.mkShell {
					packages = [
						toolchain
						pkgs.bacon

						pkgs.pyright
						pkgs.uv
					];

					RUST_SRC_PATH = "${tc.rust-src}/lib/rustlib/src/rust/library";
					
					LIBTORCH_USE_PYTORCH = "1";

					shellHook = ''
						echo "Syncing python virtual env with uv ..."
						uv sync
						
						export PATH="$PWD/.venv/bin:$PATH"
					'';
				};
				packages.default = crate;
			});
}
