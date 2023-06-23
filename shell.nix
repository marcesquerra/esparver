let
  sources = import ./nix/sources.nix;
  rust-overlay = import sources.rust-overlay;
  overlays = [rust-overlay];
  # overlays = [];
  pkgs = import sources.nixpkgs { inherit overlays ; config = { allowUnfree = true;}; };
in
let
  rustChannel = (pkgs.rust-bin.stable."1.70.0");
  rustPackage = rustChannel.default;
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
  bacon = getFromCargo {
    src = sources.bacon;
    cargoSha256 = "sha256-6eLsj7YY5bVNw6UeLleiftFr5zJh+9b7vrdv7ivBvlw=";
  };
  niv = ((import sources.niv) {}).niv;
  cargo-watch = getFromCargo {
    src = sources.cargo-watch;
    cargoSha256 = "sha256-C4uqNMyMQLbU3pBiVAoJriYwQ6q+HmodiOyxEFsVWQI=";
  };
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
      rust-analyzer
      bacon
      cargo-watch
      pkgs.cargo-release
      cargo-next
      cargo-next-go
    ];
    shellHook = ''
      export RUST_SRC_PATH="${rust-src}/lib/rustlib/src/rust/library"
    '';
  }