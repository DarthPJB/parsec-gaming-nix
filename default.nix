{ lib, stdenv, fetchurl, alsaLib, curl, dbus, ffmpeg_4, libGL, libpulseaudio,
  libpng, libva, jq, openssl, runCommand, udev, xorg, wayland }:

stdenv.mkDerivation rec {
  pname = "parsec";
  version = "150-90c";

  src = fetchurl {
    url = "https://builds.parsecgaming.com/package/parsec-linux.deb";
    sha256 = "sha256-rFSdl7BgnuJAj6w5in0/yszO8b5qcr9b+wjF1WkAU70=";
  };

  # The upstream deb package is out of date and doesn't work out of the box
  # anymore due to api.parsecgaming.com being down. Auto-updating doesn't work
  # because it doesn't patchelf the dynamic dependencies. Instead, "manually"
  # fetch the latest binaries.
  latest_appdata = fetchurl {
    url = "https://builds.parsecgaming.com/channel/release/appdata/linux/latest";
    sha256 = "sha256-6urXMrh43viJeNK3bK/T0dJDQYi73YhpZZoSdHltP/M=";
  };

  latest_parsecd_so = runCommand "latest_parsecd_so" { } ''
    cat ${latest_appdata} | ${jq}/bin/jq --raw-output .so_name | tee $out
  '';

  parsecd_so = fetchurl {
    url = "https://builds.parsecgaming.com/channel/release/binary/linux/gz/${builtins.readFile latest_parsecd_so}";
    sha256 = "sha256-rdppgVCuLUvrU9eKiDJedngjsIwAJd2YGiZiTGDHi4E=";
  };

  postPatch = ''
    cp $latest_appdata usr/share/parsec/skel/appdata.json
    cp $parsecd_so usr/share/parsec/skel/${builtins.readFile latest_parsecd_so}
  '';

  libjpeg8 = stdenv.mkDerivation (finalAttrs: {
    pname = "libjpeg";
    version = "8";

    src = fetchurl {
      url = "http://www.ijg.org/files/jpegsrc.v8.tar.gz";
      sha256 = "sha256-F7qlt6yz8PjRXXPdJBbLk5ilWzM0pak1nSeNjealC6w=";
    };

    outputs = [ "out" "lib" ];
  });

  runtimeDependencies = [
    alsaLib (lib.getLib dbus) (lib.getLib curl) (lib.getLib libjpeg8.lib)
    libGL libpulseaudio libpng libva (lib.getLib openssl) (lib.getLib stdenv.cc.cc)
    (lib.getLib udev) xorg.libX11 xorg.libXcursor xorg.libXfixes xorg.libXi xorg.libXinerama
    xorg.libXrandr xorg.libXScrnSaver wayland (lib.getLib ffmpeg_4)
  ];

  unpackPhase = ''
    ar p "$src" data.tar.xz | tar xJ
  '';

  installPhase = ''
    mkdir -p $out/bin $out/libexec
    cp usr/bin/parsecd $out/libexec
    cp -r usr/share/parsec/skel $out/libexec
    # parsecd is a small wrapper binary which copies skel/* to ~/.parsec and
    # then runs from there. Unfortunately, it hardcodes the /usr/share/parsec
    # path, and patching that would be annoying. Instead, just reproduce the
    # install logic in a wrapper script.
    cat >$out/bin/parsecd <<EOF
    #! /bin/sh
    mkdir -p \$HOME/.parsec
    ln -sf $out/libexec/skel/* \$HOME/.parsec
    exec $out/libexec/parsecd "\$@"
    EOF
    chmod +x $out/bin/parsecd
  '';

  postFixup = ''
    # We do not use autoPatchelfHook since we need runtimeDependencies rpath to
    # also be set on the .so, not just on the main executable.
    patchelf --set-interpreter "$(cat $NIX_CC/nix-support/dynamic-linker)" \
        $out/libexec/parsecd
    rpath=""
    for dep in $runtimeDependencies; do
      rpath="$rpath''${rpath:+:}$dep/lib"
    done
    patchelf --set-rpath "$rpath" $out/libexec/parsecd
    patchelf --set-rpath "$rpath" $out/libexec/skel/*.so
  '';

  meta = with lib; {
    description = "Remotely connect to a gaming PC for a low latency remote computing experience";
    homepage = "https://parsecgaming.com/";
    license = licenses.unfree;
    maintainers = with maintainers; [ delroth ];
  };
}
