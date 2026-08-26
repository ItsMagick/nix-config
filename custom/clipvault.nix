{
  lib,
  rustPlatform,
  clipvault-src,
}:

rustPlatform.buildRustPackage {
  pname = "clipvault";
  version = "unstable";

  src = clipvault-src;

  cargoLock = {
    lockFile = "${clipvault-src}/Cargo.lock";
    allowBuiltinFetchGit = true;
  };
  preCheck = ''
    export HOME=$(mktemp -d)
  '';
}
