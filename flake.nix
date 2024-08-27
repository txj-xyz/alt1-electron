{
  inputs = { nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable"; };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) stdenv lib;
      packageList = with pkgs; [
        mesa
        pango
        expat
        nspr
        nss
        cups
        libdrm
        dbus
        glib
        dbus-glib
        atk
        cairo
        alsa-lib
        at-spi2-atk
        libxkbcommon # paradox launcher
        xorg.libXcomposite
        # xorg.libXtst #
        xorg.libXrandr
        xorg.libXext
        xorg.libX11
        xorg.libXfixes
        xorg.libxcb
        xorg.libXdamage
        gtk2
        libappindicator-gtk2
        gtk3
        libappindicator-gtk3
        libGL
        libva
        pipewire
        libglvnd
        libudev0-shim
        # fontconfig
        # freetype
        # harfbuzz #
        # libthai #
        # gdb #
        # lsof #
        # file #
        # mesa.llvmPackages.llvm.lib #
        # vulkan-loader #
        # wayland
        # xorg.libxshmfence
        # xorg.libXxf86vm
        # elfutils
        # xorg.libXinerama
        # xorg.libXcursor
        # xorg.libXrender
        # xorg.libXScrnSaver
        # xorg.libXi
        # xorg.libSM

        # xorg.libICE
        # gnome2.GConf
        # curlWithGnuTls
        # libcap
        # SDL2

        # libusb1
        # gsettings-desktop-schemas
        # ffmpeg

        # xorg.libXt
        # xorg.libXmu
        # libogg
        # libvorbis
        # SDL

        # SDL2_image
        # glew110
        # libidn
        # tbb
        # zlib
        # udev
        # bzip2
        # flac
        # libglut
        # libjpeg
        # libpng
        # libpng12
        # libsamplerate
        # libmikmod
        # libtheora
        # libtiff
        # pixman
        # speex
        # SDL_image
        # SDL_ttf
        # SDL_mixer
        # SDL2_ttf
        # SDL2_mixer
        # libdbusmenu-gtk2
        # libindicator-gtk2
        # libdbusmenu-gtk3
        # libindicator-gtk3
        # libcaca
        # libcanberra
        # libgcrypt
        # libunwind
        # libvpx
        # librsvg
        # xorg.libXft
        # libvdpau
        # attr
        # libkrb5
        # keyutils
        # at-spi2-core   # CrossCode
        # gst_all_1.gstreamer
        # gst_all_1.gst-plugins-ugly
        # gst_all_1.gst-plugins-base
        # json-glib # paradox launcher (Stellaris)
        # libdrm
        # libvorbis # Dead Cells
        # libxcrypt # Alien Isolation, XCOM 2, Company of Heroes 2
        # mono
        # ncurses # Crusader Kings III
        # openssl
        # xorg.xkeyboardconfig
        # xorg.libpciaccess
        # xorg.libXScrnSaver # Dead Cells
        # icu # dotnet runtime, e.g. Stardew Valley
        # zlib
        # freetype
        # gdk-pixbuf
        # fontconfig
        # libGLU
        # libuuid
        # libbsd
        # libidn2
        # libpsl
        # nghttp2.lib
        # rtmpdump
        # egl-wayland
        # wayland 
        # elogind 
        # seatd
      ];
      fhs = pkgs.buildFHSUserEnv {
        name = "fhs_env";
        targetPkgs = pkgs: packageList;
        runscript = "bash";
      };
    in {
      packages.${system}.alt1-toolkit = stdenv.mkDerivation {
        name = "alt1-toolkit-electron";
        src = ./.;
        installPhase = ''
                            mkdir -p $out/lib/alt1-toolkit $out/bin
                            cp -r $src/* $out/lib/alt1-toolkit
                            cp $src/tools/alt1-toolkit $out/bin
                    	cat > $out/bin/alt1-toolkit-launch.sh <<EOF
          #!/usr/bin/env bash
          exec ${fhs}/bin/fhs_env $out/bin/alt1-toolkit
          EOF
                            chmod +x $out/bin/alt1-toolkit
                    	chmod +x $out/bin/alt1-toolkit-launch.sh
        '';
      };
      apps.${system}.alt1-toolkit = {
        program =
          "${self.packages.${system}.alt1-toolkit}/bin/alt1-toolkit-launch.sh";
        type = "app";
      };
      devShells.${system}.default = fhs.env;
      formatter.${system} = pkgs.nixfmt;
    };
}
