{
	description = "python devenv with uv";

	inputs = {
		nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

		flake-utils.url = "github:numtide/flake-utils";
	};

	outputs = { self, nixpkgs, flake-utils, ... }:
		flake-utils.lib.eachDefaultSystem (system:
			let
				pkgs = import nixpkgs { inherit system; };
			in {
				devShells.default = pkgs.mkShell {
					packages = [
						pkgs.pyright
						pkgs.uv
					];

					shellHook = ''
						echo "Syncing python virtual env with uv ..."
						uv sync
						
						export PATH="$PWD/.venv/bin:$PATH"
					'';
				};
			});
}
