# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
  nixos-hardware,
}:
lib.nixosSystem {
  inherit system;

  modules = [
    # this runs as a MicroVM
    microvm.nixosModules.microvm

    # Try to add some HW quirks
    nixos-hardware.nixosModules.lenovo-thinkpad-t14
    nixos-hardware.nixosModules.common-cpu-intel
    nixos-hardware.nixosModules.common-gpu-intel

    {
     # This is here because of i915 module requires some firmware
     hardware.enableRedistributableFirmware = true;
     hardware.enableAllFirmware = true;
     nixpkgs.config.allowUnfree = true;
    }

    ../../modules/users/accounts.nix
    {
      ghaf.users.accounts.enable = true;
    }
    ../../modules/development/ssh.nix
    {
      ghaf.development.ssh.daemon.enable = true;
    }
    ../../modules/development/debug-tools.nix
    {
      ghaf.development.debug.tools.enable = true;
    }
    # Uncomment this to enable "real" graphics with weston and apps
    #../../modules/development/packages.nix
    #../../user-apps/default.nix
    ../../modules/graphics/weston.nix
    {
      lib.options.ghaf.profiles.graphics.enable = true;
      ghaf.graphics.weston.enable = true;
    }

    ({ config, lib, pkgs, ... }: {
      system.stateVersion = config.system.nixos.version;

      microvm = {
        mem = 2048;
        hypervisor = "qemu";
        storeDiskType = "squashfs";
        interfaces = [{
          type = "tap";
          id = "vm-guivm";
          mac = "02:00:00:02:03:04";
        }];
      };

      networking = {
        enableIPv6 = false;
        firewall.allowedTCPPorts = [22];
        useNetworkd = true;
        hostName = "guivm";
      };

      # Set internal network's interface name to ethint0
      systemd.network.links."10-ethint0" = {
        matchConfig.PermanentMACAddress = "02:00:00:02:03:04";
        linkConfig.Name = "ethint0";
      };

      systemd.network = {
        enable = true;
        networks."10-ethint0" = {
          matchConfig.MACAddress = "02:00:00:02:03:04";
          addresses = [
            {
              # IP-address for debugging subnet
              addressConfig.Address = "192.168.101.11/24";
            }
          ];
          routes =  [
            { routeConfig.Gateway = "192.168.101.1"; }
          ];
          linkConfig.RequiredForOnline = "routable";
          linkConfig.ActivationPolicy = "always-up";
        };
      };

      # Some people say that the bios might be needed
      # I tried with the default one and with seabios.
      # Nothing works

      #microvm.qemu.bios = {
      #  enable = true;
      #  #path = "${pkgs.seabios}/Csm16.bin";
      #};

      # From the microvm example. May be useful when the GPU is actually working

      #services.getty.autologinUser = "user";
      #users.users.user = {
      #  password = "";
      #  group = "user";
      #  isNormalUser = true;
      #  extraGroups = [ "wheel" "video" ];
      #};
      #users.groups.user = {};
      #security.sudo = {
      #  enable = true;
      #  wheelNeedsPassword = false;
      #};

      #environment.sessionVariables = {
      #  WAYLAND_DISPLAY = "wayland-1";
      #  DISPLAY = ":0";
      #  QT_QPA_PLATFORM = "wayland"; # Qt Applications
      #  GDK_BACKEND = "wayland"; # GTK Applications
      #  XDG_SESSION_TYPE = "wayland"; # Electron Applications
      #  SDL_VIDEODRIVER = "wayland";
      #  CLUTTER_BACKEND = "wayland";
      #};

      #systemd.user.services.wayland-proxy = {
      #  enable = true;
      #  description = "Wayland Proxy";
      #  serviceConfig = with pkgs; {
      #    # Environment = "WAYLAND_DISPLAY=wayland-1";
      #    ExecStart = "${wayland-proxy-virtwl}/bin/wayland-proxy-virtwl --virtio-gpu";
      #    Restart = "on-failure";
      #    RestartSec = 1;
      #  };
      #  wantedBy = [ "default.target" ];
      #};

      #environment.systemPackages = with pkgs; [
      #  xdg-utils # Required
      #];

      #hardware.opengl.enable = true;
    })
  ];
}
