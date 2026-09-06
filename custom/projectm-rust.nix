{
  lib,
  rustPlatform,
  pkg-config,
  cmake,
  makeWrapper,
  libGL,
  mesa,
  pulseaudio,
  alsa-lib,
  dbus,
  libxkbcommon,
  libdecor,
  wayland,
  wayland-protocols,
  wayland-scanner,
  libx11,
  libxext,
  libxcursor,
  libxi,
  libxrandr,
  libxrender,
  libxfixes,
  libxinerama,
  libxscrnsaver,
  libxtst,
  libxxf86vm,
  libdrm,
  libGLU,
  libpthreadstubs,
  ibus,
  libxcb,
  vulkan-headers,
  vulkan-loader,
  xcbutil,
  xcbutilwm,
  xcbutilkeysyms,
  writeShellScriptBin,
  frontend-sdl-rust-src,
}:
let
  buildInputsList = [
    libGL
    mesa
    pulseaudio
    alsa-lib
    dbus
    libxkbcommon
    libdecor
    wayland
    wayland-protocols
    libx11
    libxext
    libxcursor
    libxi
    libxrandr
    libxrender
    libxfixes
    libxinerama
    libxscrnsaver
    libxtst
    libxxf86vm
    libdrm
    libGLU
    libpthreadstubs
    ibus
    libxcb
    vulkan-headers
    vulkan-loader
    xcbutil
    xcbutilwm
    xcbutilkeysyms
  ];

  rpathLibs = [
    libGL
    libxkbcommon
    libdecor
    wayland
    libx11
    libxext
    libxcursor
    libxi
    libxrandr
    libxrender
    libxfixes
    libxinerama
    libxscrnsaver
    libxtst
    alsa-lib
    pulseaudio
    dbus
    libdrm
    libxxf86vm
    libxcb
    vulkan-loader
    xcbutil
    xcbutilwm
    xcbutilkeysyms
  ];

  cmakeInstallLibFix = writeShellScriptBin "cmake" ''
    if [ "$1" = "--build" ] || [ "$1" = "--install" ] || [ "$1" = "--open" ]; then
      exec ${cmake}/bin/cmake "$@"
    else
      exec ${cmake}/bin/cmake -DCMAKE_INSTALL_LIBDIR=lib "$@"
    fi
  '';
in
rustPlatform.buildRustPackage {
  pname = "projectm-sdl-rust";
  version = "unstable";

  src = frontend-sdl-rust-src;

  cargoLock = {
    lockFile = "${frontend-sdl-rust-src}/Cargo.lock";
  };

  nativeBuildInputs = [
    pkg-config
    cmakeInstallLibFix
    makeWrapper
    wayland-scanner
    rustPlatform.bindgenHook
  ];

  buildInputs = buildInputsList;

  CMAKE_PREFIX_PATH = lib.concatStringsSep ":" (
    lib.concatMap (p: [
      "${lib.getDev p}"
      "${lib.getLib p}"
    ]) buildInputsList
  );

  postInstall = ''
    for bin in $out/bin/*; do
      wrapProgram "$bin" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath rpathLibs}"
    done
  '';

  meta = with lib; {
    description = "projectM visualizer frontend written in Rust using SDL3, statically linked";
    homepage = "https://github.com/projectM-visualizer/frontend-sdl-rust";
    mainProgram = "frontend-sdl-rust";
  };
}
