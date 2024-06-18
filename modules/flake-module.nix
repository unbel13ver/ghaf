# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Modules to be exported from Flake
#
{inputs, ...}: {
  imports = [
    ./disko/flake-module.nix
    ./hardware/flake-module.nix
  ];

  flake.nixosModules = {
    common.imports = [
      ./common
      {ghaf.development.nix-setup.nixpkgs = inputs.nixpkgs;}
    ];
    desktop.imports = [./desktop];
    host.imports = [./host];
    imx8.imports = [./imx8];
    jetpack.imports = [./jetpack];
    jetpack-microvm.imports = [./jetpack-microvm];
    lanzaboote.imports = [./lanzaboote];
    microvm.imports = [(import ./microvm {inherit inputs;})];
    polarfire.imports = [./polarfire];
    reference-appvms.imports = [./reference/appvms];
    reference-programs.imports = [./reference/programs];
  };
}
