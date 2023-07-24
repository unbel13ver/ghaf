# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  stdenv,
  pkgs,
}:
stdenv.mkDerivation {
  name = "i915ovmf";
  src = ./i915ovmf.rom;
  phases = ["installPhase"];
  installPhase = ''
    mkdir -p $out/i915ovmf
    ln -s $src $out/i915ovmf/i915ovmf.rom
  '';
}
