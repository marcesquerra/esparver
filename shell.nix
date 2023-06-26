let
  flake = (import
    (
      let lock = builtins.fromJSON (builtins.readFile ./flake.lock); in
      fetchTarball {
        url = "https://github.com/edolstra/flake-compat/archive/${lock.nodes.flake-compat.locked.rev}.tar.gz";
        sha256 = lock.nodes.flake-compat.locked.narHash;
      }
    )
    { src = ./.; }
  ).defaultNix.packages.x86_64-linux;
  sources = import ./nix/sources.nix;
  rust-overlay = import sources.rust-overlay;
  overlays = [rust-overlay];
  # overlays = [];
  pkgs = import sources.nixpkgs { inherit overlays ; config = { allowUnfree = true;}; };
in
let
  rustPackage = flake.rustPackage;
  rust-src = flake.rust-src;
  niv = ((import sources.niv) {}).niv;
  git = "${pkgs.git}/bin/git";
  cargo-next-bin = pkgs.writeShellScriptBin "cargo-next-bin" ''
    ${rustPackage}/bin/cargo release --sign "$@" patch
  '';
  cargo-next = pkgs.writeShellScriptBin "cargo-next" ''
    ${cargo-next-bin}/bin/cargo-next-bin
  '';
  cargo-next-go = pkgs.writeShellScriptBin "cargo-next-go" ''
    ${cargo-next-bin}/bin/cargo-next-bin --no-confirm --execute
  '';
in
  pkgs.mkShell {
    name = "polymono-shell";
    nativeBuildInputs = [
      niv
      rustPackage
      flake.cargo-watch
      pkgs.cargo-release
      cargo-next
      cargo-next-go
      flake.bacon
    ];
    shellHook = ''
      export RUST_SRC_PATH="${rust-src}/lib/rustlib/src/rust/library"
    '';
  }