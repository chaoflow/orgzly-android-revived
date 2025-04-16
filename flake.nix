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

        # We're on kotlin 1.9 for now:
        # https://github.com/orgzly-revived/orgzly-android-revived/issues/454
        jre = pkgs.jdk21_headless;
        kotlin19 = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "kotlin";
          version = "1.9.24";

          src = pkgs.fetchurl {
            url = "https://github.com/JetBrains/kotlin/releases/download/v${finalAttrs.version}/kotlin-compiler-${finalAttrs.version}.zip";
            sha256 = "sha256-63to4BAp+me8jQYO5UwSAY8sYN3EOM8h2xRRcimqaTs=";
          };

          propagatedBuildInputs = [ jre ];
          nativeBuildInputs = [
            pkgs.makeWrapper
            pkgs.unzip
          ];

          installPhase = ''
            mkdir -p $out
            rm "bin/"*.bat
            mv * $out

            for p in $(ls $out/bin/) ; do
              wrapProgram $out/bin/$p --prefix PATH ":" ${jre}/bin ;
            done

            if [ -f $out/LICENSE ]; then
              install -D $out/LICENSE $out/share/kotlin/LICENSE
              rm $out/LICENSE
            fi
          '';
        });

      in
      {
        inherit androidComposition;

        devShells = {
          default = pkgs.mkShell rec {
            ANDROID_HOME = "${androidComposition.androidsdk}/libexec/android-sdk";

            buildInputs = with pkgs; [
              google-java-format
              gradle_8
              jre
              kotlin19
              kotlin-language-server
              ktlint
            ];
          };
        };
      }
    );
}
