# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  microvm,
  system,
}:
lib.nixosSystem {
  inherit system;

  modules = [
    # this runs as a MicroVM
    microvm.nixosModules.microvm

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
    #../../modules/development/packages.nix
    #../../user-apps/default.nix
    ../../modules/graphics/weston.nix
    #../../modules/windows/launcher.nix

    ({ config, lib, pkgs, ... }: {
      microvm = {
        hypervisor = "qemu";
        graphics.enable = true;
        interfaces = [{
          type = "tap";
          id = "vm-guivm";
          mac = "02:00:00:02:01:01";
        }];
      };

      networking.hostName = "graphical-microvm";
      system.stateVersion = config.system.nixos.version;

      # Extend the PCI memory window
      nixpkgs.overlays = [
        (self: super: {
          qemu_kvm = super.qemu_kvm.overrideAttrs (self: super: {
            patches = super.patches ++ [./qemu-aarch-memory.patch];
          });
        })
      ];

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
