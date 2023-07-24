# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Generic x86_64 computer -target
{
  self,
  lib,
  nixos-generators,
  nixos-hardware,
  microvm,
}: let
  name = "generic-x86_64";
  system = "x86_64-linux";
  formatModule = nixos-generators.nixosModules.raw-efi;
  generic-x86 = variant: extraModules: let
    hostConfiguration = lib.nixosSystem {
      inherit system;
      specialArgs = {inherit lib;};
      modules =
        [
          (import ../modules/host {
            inherit self microvm netvm guivm;
          })

          {
            virtualisation = {
              libvirtd = {
                enable = true;
                qemu.ovmf.enable = true;
                qemu.runAsRoot = false;
                onBoot = "ignore";
                onShutdown = "shutdown";
              };
            };

            ghaf = {
              hardware.x86_64.common.enable = true;
              # Enable all the default UI applications
              profiles = {
                #applications.enable = true;
                #TODO clean this up when the microvm is updated to latest
                release.enable = variant == "release";
                debug.enable = variant == "debug";
              };
            };
          }

          nixos-hardware.nixosModules.lenovo-thinkpad-t14
          nixos-hardware.nixosModules.common-cpu-intel

          formatModule

          #TODO: how to handle the majority of laptops that need a little
          # something extra?
          # SEE: https://github.com/NixOS/nixos-hardware/blob/master/flake.nix
          # nixos-hardware.nixosModules.lenovo-thinkpad-x1-10th-gen

          {
            boot.kernelParams = [
              "intel_iommu=on,igx_off,sm_on"
              "iommu=pt"

              # TODO: Change per your device
              # Passthrough Intel WiFi card
              "vfio-pci.ids=8086:a0f0,8086:9b41"
            ];

            boot.kernelPatches = [
             {
               name = "Add IOMMU debug";
               patch = null;

               extraStructuredConfig = with lib.kernel; {
                 IOMMU_DEBUGFS = yes;
                 INTEL_IOMMU_DEBUGFS = yes;
               };
             }
            ];

            boot = {
              blacklistedKernelModules = [ "snd_hda_intel" "i915" ];
              postBootCommands = ''
                for i in /sys/class/vtconsole/*/bind
                do
                        echo 0 >$i
                done
                echo "vfio-pci" > /sys/bus/pci/devices/0000:00:02.0/driver_override
                modprobe -i vfio-pci
             '';
            };
          }
        ]
        ++ (import ../modules/module-list.nix)
        ++ extraModules;
    };
    netvm = "netvm-${name}-${variant}";
    guivm = "guivm-${name}-${variant}";
  in {
    inherit hostConfiguration netvm guivm;
    name = "${name}-${variant}";
    netvmConfiguration =
      (import ../microvmConfigurations/netvm {
        inherit lib microvm system;
      })
      .extendModules {
        modules = [
          {
            microvm.devices = [
              {
                bus = "pci";
                path = "0000:00:14.3";
              }
            ];

            # For WLAN firmwares
            hardware.enableRedistributableFirmware = true;

            networking.wireless = {
              enable = true;

              # networks."SSID_OF_NETWORK".psk = "WPA_PASSWORD";
            };
          }
        ];
      };
    guivmConfiguration =
      (import ../microvmConfigurations/guivm {
        inherit lib microvm system nixos-hardware;
      })
      .extendModules {
        modules = [
          {
            microvm.devices = [
              {
                bus = "pci";
                path = "0000:00:02.0";
              }
            ];
            microvm.kernelParams = [
              "nosplash oprofile.timer=1 i915.enable_psr=0 i915.enable_dc=0"
            ];
          }
        ];
      };
    package = hostConfiguration.config.system.build.${hostConfiguration.config.formatAttr};
  };
  debugModules = [../modules/development/usb-serial.nix {ghaf.development.usb-serial.enable = true;}];
  targets = [
    (generic-x86 "debug" debugModules)
    (generic-x86 "release" [])
  ];
in {
  nixosConfigurations =
    builtins.listToAttrs (map (t: lib.nameValuePair t.name t.hostConfiguration) targets)
    // builtins.listToAttrs (map (t: lib.nameValuePair t.netvm t.netvmConfiguration) targets)
    // builtins.listToAttrs (map (t: lib.nameValuePair t.guivm t.guivmConfiguration) targets);
  packages = {
    x86_64-linux =
      builtins.listToAttrs (map (t: lib.nameValuePair t.name t.package) targets);
  };
}
