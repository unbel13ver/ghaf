# Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
{
  self,
  netvm,
}: {config, ...}: {
  microvm.host.enable = false;

  microvm.vms."${netvm}" = {
    flake = self;
    autostart = true;
  };
}
