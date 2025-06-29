{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        variant = "debug";
        procpsOrig = pkgs.procps.overrideAttrs (oldAttrs: {
          version = "3.3.17";
          src = pkgs.fetchurl {
            url = "mirror://sourceforge/procps-ng/procps-ng-3.3.17.tar.xz";
            hash = "sha256-RRiz56r9NOwH0AY9JQ/UdJmbILIAIYw65W9dIRPxQbQ=";
          };
        });

        # X11 and other native dependencies from binding.gyp
        x11Deps = with pkgs; [
          xorg.libxcb
          xorg.xcbutilwm
          xorg.xcbutil
          xorg.xcbutilimage
          xorg.xcbutilkeysyms
          xorg.xcbutilrenderutil
          xorg.xcbproto
          xorg.libX11
          xorg.libXcomposite
          xorg.libXdamage
          xorg.libXext
          xorg.libXfixes
          xorg.libXrandr
          xorg.libXrender
          xorg.libXtst
          libGL
          procpsOrig
          pkg-config
        ];

        # All required system dependencies
        electronDeps = with pkgs;
          [
            mesa
            pango
            expat
            nspr
            nss
            cups
            libdrm
            dbus
            glib
            atk
            cairo
            alsa-lib
            at-spi2-atk
            libxkbcommon
            gtk3
            libappindicator-gtk3
            libva
            pipewire
            libglvnd
            vips
            nodejs
          ] ++ x11Deps;

        src = ./.;
        alt1lite = pkgs.stdenv.mkDerivation (finalAttrs: {
          pname = "alt1lite";
          version = "0.0.1";
          inherit src;

          yarnOfflineCache = pkgs.fetchYarnDeps {
            yarnLock = src + "/yarn.lock";
            hash = "sha256-Lj66aS0tXyjDHzVctaPiAZ0YYl+VCyS2bqoRlcnmSr4=";
          };

          env = {
            ELECTRON_SKIP_BINARY_DOWNLOAD = "1";
            npm_config_nodedir = pkgs.electron.headers;
            SHARP_IGNORE_GLOBAL_LIBVIPS = "1";
            SHARP_LIBVIPS_VERSION = pkgs.vips.version;
            NIX_CFLAGS_COMPILE = toString [
              "-I${pkgs.glib.dev}/include/glib-2.0"
              "-I${pkgs.glib.out}/lib/glib-2.0/include"
              "-I${pkgs.vips.dev}/include"
              "-lvips"
            ];
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
              pkgs.vips
              pkgs.glib
              pkgs.libpng
              pkgs.libjpeg
              pkgs.libtiff
            ];
            doDist = false;
          };

          buildInputs = [
            pkgs.vips
            pkgs.vips.dev
            pkgs.xorg.libxcb
            pkgs.xorg.xcbutilwm
            procpsOrig
          ] ++ electronDeps;

          nativeBuildInputs = [
            pkgs.yarnConfigHook
            pkgs.yarnBuildHook
            pkgs.npmHooks.npmInstallHook
            pkgs.nodejs
            pkgs.typescript
            pkgs.nodePackages.ts-node
            pkgs.nodePackages.typescript
            pkgs.pkg-config
            pkgs.makeWrapper
            pkgs.vips
            pkgs.glib.dev
            pkgs.vips.dev
            (pkgs.python311.withPackages (ps: [ ps.distutils ]))
          ];

          preConfigure = ''
            export npm_config_target=${pkgs.electron.version}
            export npm_config_runtime=electron
            export npm_config_disturl=https://electronjs.org/headers
            export npm_config_arch=x64
            export npm_config_platform=linux
            export npm_config_build_from_source=true
          '';

          yarnBuildScript = "electron-rebuild";

          yarnBuildFlags = [
            "-w alt1lite"
            "-c.electronDist=${pkgs.electron}/libexec/electron"
            "-c.electronVersion=${pkgs.electron.version}"
          ] ++ (if variant == "debug" then [ "--debug" ] else [ ]);

          installPhase = ''
            runHook preInstall
            if [ "${variant}" == "debug" ]; then
              yarn --offline electron-rebuild -f -w alt1lite --only sharp -c.electronDist=${pkgs.electron}/libexec/electron -c.electronVersion=${pkgs.electron.version}
            fi
            yarn --offline build --mode development
            # resources
            mkdir -p "$out/share/lib/alt1lite" "$out/bin"
            ls -alh ./build
            cp -r ./dist/* "$out/share/lib/alt1lite"
            cp -r ./node_modules "$out/share/lib/alt1lite"
            cp -r ./build "$out/share/lib"
            cp -r ./bin/* "$out/bin"
            # executable wrapper
            makeWrapper '${pkgs.electron}/bin/electron' "$out/bin/alt1lite" \
              --add-flags "--inspect=9228 $out/share/lib/alt1lite/alt1lite.bundle.js"

            runHook postInstall
          '';
        });

      in {
        packages.default = alt1lite;

        apps.default = {
          type = "app";
          program = "${alt1lite}/bin/alt1lite";
        };

        devShells.default = pkgs.mkShell {
          packages = [
            pkgs.nodejs
            pkgs.yarn
            pkgs.python3
            pkgs.pkg-config
            pkgs.make
            pkgs.gcc
            pkgs.electron
          ] ++ electronDeps ++ x11Deps;

          ELECTRON_VERSION = pkgs.lib.versions.majorMinor pkgs.electron.version;
          PKG_CONFIG_PATH = pkgs.lib.makeSearchPathOutput "dev" "lib/pkgconfig"
            (electronDeps ++ x11Deps);
        };

        formatter.${system} = pkgs.nixfmt;
      });
}
