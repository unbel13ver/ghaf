# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.ghaf.development.debug.tools;
  vhost-device = pkgs.callPackage ../../user-apps/vhost-device {};
  nc-vhost = pkgs.callPackage ../../user-apps/nc-vhost {};
in
  with lib; {
    options.ghaf.development.debug.tools = {
      enable = mkEnableOption "Debug Tools";
    };

    config = mkIf cfg.enable {
      environment.systemPackages = with pkgs; [
        # For lspci:
        pciutils

        # For lsusb:
        usbutils

        # Useful in NetVM
        ethtool

        # Basic monitors
        htop
        iftop
        iotop

        traceroute
        dig

        waypipe
        vhost-device
        socat
        nc-vhost
      ];
    };
  }
