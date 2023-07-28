# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  pkgs,
  ...
}: let
  configHost = config;
  waypipe-ssh = pkgs.callPackage ../../../user-apps/waypipe-ssh {};
  appvmBaseConfiguration = {
    imports = [
      ({lib, ...}: {
        ghaf = {
          users.accounts.enable = lib.mkDefault configHost.ghaf.users.accounts.enable;
          profiles.graphics.enable = true;
          profiles.applications.enable = true;
          development = {
            # NOTE: SSH port also becomes accessible on the network interface
            #       that has been passed through to NetVM
            ssh.daemon.enable = lib.mkDefault configHost.ghaf.development.ssh.daemon.enable;
            debug.tools.enable = lib.mkDefault configHost.ghaf.development.debug.tools.enable;
          };
        };

        users.users.${configHost.ghaf.users.accounts.user}.openssh.authorizedKeys.keyFiles = ["${waypipe-ssh}/keys/waypipe-ssh.pub"];

        networking.hostName = "appvm";
        system.stateVersion = lib.trivial.release;

        nixpkgs.buildPlatform.system = configHost.nixpkgs.buildPlatform.system;
        nixpkgs.hostPlatform.system = configHost.nixpkgs.hostPlatform.system;

        networking = {
          enableIPv6 = false;
          interfaces.ethint0.useDHCP = false;
          firewall.allowedTCPPorts = [22];
          firewall.allowedUDPPorts = [67];
          useNetworkd = true;
        };

        microvm = {
          mem = 2048;
          hypervisor = "qemu";
          qemu.bios.enable = true;
          storeDiskType = "squashfs";
          interfaces = [
            {
              type = "tap";
              id = "vm-appvm";
              mac = "02:00:00:03:03:03";
            }
          ];
        };

        networking.nat = {
          enable = true;
          internalInterfaces = ["ethint0"];
        };

        # Set internal network's interface name to ethint0
        systemd.network.links."10-ethint0" = {
          matchConfig.PermanentMACAddress = "02:00:00:03:03:03";
          linkConfig.Name = "ethint0";
        };

        systemd.network = {
          enable = true;
          networks."10-ethint0" = {
            matchConfig.MACAddress = "02:00:00:03:03:03";
            addresses = [
              {
                # IP-address for debugging subnet
                addressConfig.Address = "192.168.101.4/24";
              }
            ];
            routes = [
              {routeConfig.Gateway = "192.168.101.1";}
            ];
            linkConfig.RequiredForOnline = "routable";
            linkConfig.ActivationPolicy = "always-up";
          };
        };

        imports = import ../../module-list.nix;
      })
    ];
  };
  cfg = config.ghaf.virtualization.microvm.appvm;
in {
  options.ghaf.virtualization.microvm.appvm = {
    enable = lib.mkEnableOption "appvm";

    extraModules = lib.mkOption {
      description = ''
        List of additional modules to be imported and evaluated as part of
        appvm's NixOS configuration.
      '';
      default = [];
    };
  };

  config = lib.mkIf cfg.enable {
    microvm.vms."appvm" = {
      autostart = true;
      config =
        appvmBaseConfiguration
        // {
          imports =
            appvmBaseConfiguration.imports
            ++ cfg.extraModules;
        };
      specialArgs = {inherit lib;};
    };
  };
}
