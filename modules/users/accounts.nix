# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  config,
  lib,
  options,
  ...
}:
# account for the development time login with sudo rights
let
  cfg = config.ghaf.users.accounts;
in
  with lib; {
    #TODO Extend this to allow definition of multiple users
    options.ghaf.users.accounts = {
      enable = mkEnableOption "Default account Setup";
      user = mkOption {
        default = "ghaf";
        type = with types; str;
        description = ''
          A default user to create in the system.
        '';
      };
      password = mkOption {
        default = "ghaf";
        type = with types; str;
        description = ''
          A default password for the user.
        '';
      };
    };

    config = mkIf cfg.enable {
      users = {
        # User microvm needs an access to the USB devices such as input devices.
        # Those devices are owned by root in ghaf system.
        # The proper way of fixing that is creating a Udev rule which assigns
        # usb devices to the specific group and add microvm and ghaf users to
        # that group, but I do not have an idea on how to implement that in a
        # nice and correct way, so I leave it as is for now.
        groups.root.members = ["microvm"];
        mutableUsers = true;
        users."${cfg.user}" = {
          isNormalUser = true;
          password = cfg.password;
          #TODO add "docker" use "lib.optionals"
          extraGroups = ["wheel" "video"];
        };
        groups."${cfg.user}" = {
          name = cfg.user;
          members = [cfg.user];
        };
      };
    };
  }
