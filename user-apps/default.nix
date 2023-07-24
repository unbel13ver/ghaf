# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  nixpkgs,
  flake-utils,
}: let
  systems = with flake-utils.lib.system; [
    x86_64-linux
    aarch64-linux
  ];
in
  # Combine list of attribute sets together
  lib.foldr lib.recursiveUpdate {} [
    (flake-utils.lib.eachSystem systems (system: {
      packages = let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        gala-app = pkgs.callPackage ./gala {};
        i915ovmf = pkgs.callPackage ./i915ovmf {};
      };
    }))

    {
      packages.aarch64-linux.windows-launcher = nixpkgs.legacyPackages.aarch64-linux.callPackage ./windows-launcher {};
    }
  ]
