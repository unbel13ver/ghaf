# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  stdenv,
  pkgs,
  lib,
  ...
}: stdenv.mkDerivation {
    name = "waypipe-ssh";

    buildInputs = [pkgs.openssh];

    phases = ["buildPhase" "installPhase"];

    buildPhase = ''
      echo -e "\n\n\n" | ${pkgs.openssh}/bin/ssh-keygen -o -a 100 -t ed25519 -f waypipe-ssh -C ""
    '';

    installPhase = ''
      mkdir -p $out/keys
      install ./waypipe-ssh $out/keys
      install ./waypipe-ssh.pub $out/keys
    '';

    meta = with lib; {
      description = "Helper script for launching Waypipe";
      platforms = [
        "x86_64-linux"
      ];
    };
  }
