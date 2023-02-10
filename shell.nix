let
  sources = import ./nix/sources.nix;
  rust-overlay = import sources.rust-overlay;
  overlays = [rust-overlay];
  # overlays = [];
  pkgs = import sources.nixpkgs { inherit overlays ; config = { allowUnfree = true;}; };
in
let
  rustChannel = (pkgs.rust-bin.stable."1.67.1");
  rustPackage = rustChannel.default;
    # let
    #   superRust = rustChannel.rust;
    # in
    #   superRust.override{targets = [(pkgs.rust.toRustTarget pkgs.stdenv.targetPlatform) "wasm32-unknown-unknown"];}; # {targets = [pkgs.stdenv.targetPlatform];};
  rust-src = rustChannel.rust-src;
  rustPlatform = pkgs.makeRustPlatform{
      cargo = rustPackage;
      rustc = rustPackage;
    };
  getFromCargo = {src, cargoSha256, nativeBuildInputs ? [], cargoBuildFlags ? []} :
    let
      lib = pkgs.lib;
      asName = candidates :
        let
          ts = e: if (builtins.isAttrs e) && (builtins.hasAttr "name" e) && e.name != null then e.name else toString e;
          stringCandidates = map ts candidates;
          wholeString = lib.concatStrings stringCandidates;
        in
          builtins.hashString "sha256" wholeString;
    in
      rustPlatform.buildRustPackage rec {
        inherit src cargoSha256 nativeBuildInputs cargoBuildFlags;
        pname = "cargo-${asName [src]}";
        version = "N/A";
        doCheck = false;
      };
  rust-analyzer = getFromCargo {
    src = sources.rust-analyzer;
    cargoSha256 = "sha256-gmFgGYt2aSxz5mBQqr5yCc36ZzcRXpeWjD3RZGk281A=";
  };
  niv = ((import sources.niv) {}).niv;
in
  pkgs.mkShell {
    name = "polymono-shell";
    nativeBuildInputs = [
      niv
      rustPackage
      rust-analyzer
    ];
    shellHook = ''
      export RUST_SRC_PATH="${rust-src}/lib/rustlib/src/rust/library"
    '';
  }