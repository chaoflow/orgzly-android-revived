{
  description = "Orgzly nix develop environment";
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };
  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config = {
            android_sdk.accept_license = true;
            allowUnfree = true;
          };
        };

        androidComposition = pkgs.androidenv.composeAndroidPackages {
          platformVersions = [ "34" ];
        };

      in
      {
        inherit androidComposition;

        devShells = {
          default = pkgs.mkShell rec {
            ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";

            buildInputs = with pkgs; [
              google-java-format
              gradle_8
              jdk21_headless # match with kotlin's jdk
              kotlin
              kotlin-language-server
              ktlint
            ];
          };
        };
      }
    );
}
