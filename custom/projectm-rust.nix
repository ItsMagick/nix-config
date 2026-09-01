{
  lib,
  rustPlatform,
  pkg-config,
  cmake,
  makeWrapper,
  sdl3,
  libGL,
  pulseaudio,
  libxkbcommon,
  wayland,
  xorg,
  frontend-sdl-rust-src
}:

let
  rpathLibs = [
    libGL
    sdl3
    libxkbcommon
    wayland
    xorg.libX11
    xorg.libXcursor
    xorg.libXi
    xorg.libXrandr
  ];
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
    cmake
    makeWrapper
  ];

  buildInputs = [
    sdl3
    libGL
    pulseaudio
  ];

  postInstall = ''
    for bin in $out/bin/*; do
      wrapProgram "$bin" \
        --prefix LD_LIBRARY_PATH : "${lib.makeLibraryPath rpathLibs}"
    done
  '';

  meta = with lib; {
    description = "projectM visualizer frontend written in Rust using SDL3";
    homepage = "https://github.com/projectM-visualizer/frontend-sdl-rust";
    mainProgram = "frontend-sdl-rust";
  };
}