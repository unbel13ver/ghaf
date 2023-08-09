{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
}:
rustPlatform.buildRustPackage rec {
  pname = "vhost-device";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "rust-vmm";
    repo = "vhost-device";
    rev = "main";
    sha256 = "sha256-nYJz1e3I6GpusiYloC2fHtUvtAGuPIiH/YzOvzrI/20=";
  };

  phases = ["unpackPhase" "buildPhase" "installPhase"];

  buildPhase = ''
    runHook preBuild

    cd crates/vsock
    cargo build

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    mv /build/source/target/debug/vhost-device-vsock $out/bin

    runHook postInstall
  '';

  cargoHash = "sha256-7mPjFiXd7BbAjy5av+zp7xiA+2Vmcun9T7Z4YFnOoEs=";

  #meta = with lib; {
  #  homepage = "https://gitlab.com/virtio-fs/virtiofsd";
  #  description = "vhost-user virtio-fs device backend written in Rust";
  #  maintainers = with maintainers; [ qyliss ];
  #  platforms = platforms.linux;
  #  license = with licenses; [ asl20 /* and */ bsd3 ];
  #};
}
