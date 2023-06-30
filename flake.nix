rec {
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-23.05";
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-utils.url = "github:numtide/flake-utils";
    rust-overlay.url = "github:oxalica/rust-overlay";
    bacon-src = {
      url = "github:Canop/bacon"; 
      flake = false;
    };
    crane = {
      url = "github:ipetkov/crane/v0.12.2";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    rust-analyzer-src = rec {
      url = "github:rust-lang/rust-analyzer/2023-06-26"; 
      flake = false;
    };
    cargo-watch-src = {
      url = "github:watchexec/cargo-watch/8.x"; 
      flake = false;
    };

  };

  outputs = { self, nixpkgs, flake-utils, rust-overlay, bacon-src, crane, rust-analyzer-src, cargo-watch-src, ... }:

    flake-utils.lib.eachDefaultSystem (system:

      let
        overlays = [ (import rust-overlay) ];
        pkgs = import nixpkgs {
          inherit system overlays;
        };
        rustChannel = (pkgs.rust-bin.stable."1.70.0");
        rustPackage = rustChannel.default;
        rust-src = rustChannel.rust-src;
        rust-analyzer = cargoInstall rust-analyzer-src {
          pname = "rust-analyzer";
          version = "from-flake";
          doCheck = false;
        };
        craneLib = crane.lib.${system}.overrideToolchain rustPackage;
        cargoInstall = pkg-src : extra-options :
          craneLib.buildPackage ({
            src = craneLib.cleanCargoSource pkg-src;
          } // extra-options);
        bacon = cargoInstall bacon-src {};
        cargo-watch = cargoInstall cargo-watch-src {
          doCheck = false;
        };
        esparver-package = craneLib.buildPackage {
          src = craneLib.cleanCargoSource (craneLib.path ./.);

          # Tests currently need to be run via `cargo wasi` which
          # isn't packaged in nixpkgs yet...
          doCheck = false;

          buildInputs = [
            # Add additional build inputs here
          ] ++ pkgs.lib.optionals pkgs.stdenv.isDarwin [
            # Additional darwin specific inputs can be set here
            pkgs.libiconv
          ];
        };
      in {
        checks = {
          esparver = esparver-package;
        };
        apps = rec {
          esparver = flake-utils.lib.mkApp { drv = esparver-package; };
          default = esparver;
        };
        packages = rec {
          esparver = esparver-package;
          default = esparver;
        };
        devShells.default = import ./nix/flake-shell.nix {
          inherit rustPackage rust-src cargo-watch bacon rust-analyzer;
          packages = pkgs;
        };
      }
    );  
}