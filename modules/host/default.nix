# Copyright 2024 TII (SSRC) and the Ghaf contributors
# SPDX-License-Identifier: Apache-2.0
#
# Modules that should be only imported to host
#
{ lib, pkgs, ... }:
let
  updateSources = import ./updater.nix;
  updateScript = pkgs.writeShellScriptBin "ota-update" ''
    # Function to validate the Generation path in --set mode
    validate_genpath() {
      local path="$1"
      # This pattern matches paths like
      # /nix/store/74v7ddgcv7wxb039cld5chf2n5hplxqn-nixos-system-ghaf-host-25.05.20241119.23e89b7
      local pattern="^/nix/store/[a-z0-9]{32}-nixos-system-ghaf-host-[0-9]{2}\.[0-9]{2}\.[0-9]{8}\.[a-f0-9]{7}$"

      if [[ "$path" =~ $pattern ]]; then
        return 0 # Correct
      else
        return 1 # Incorrect
      fi
    }

    # Processing --get parameter
    get_procedure() {
      # Get the list of Generations in JSON format
      local json_output
      json_output=$(nixos-rebuild list-generations --json)

      # This JSON output does not contain the Generation's /nix/store path,
      # but we really need it. So let's make a copy of this JSON with this
      # data added for every Generation that is in the system.

      # Create a temporary file to store the updated JSON
      local tmpfile
      tmpfile=$(mktemp)

      # Iterate over each Generation
      echo "$json_output" | ${pkgs.jq}/bin/jq -c '.[]' | while read -r generation_json; do
        # Extract the Generation number
        local generation
        generation=$(echo "$generation_json" | ${pkgs.jq}/bin/jq -r '.generation')

        # Run the readlink command to read the full path to the /nix/store
        local store_path
        store_path=$(readlink -f "/nix/var/nix/profiles/system-''${generation}-link")

        # Add the storePath to the JSON object
        echo "$generation_json" | ${pkgs.jq}/bin/jq --arg storePath "$store_path" '.storePath = $storePath' >> "$tmpfile"
      done

      # Combine updated objects back into an array
      updated_json=$(${pkgs.jq}/bin/jq -s '.' "$tmpfile")

      rm "$tmpfile"

      echo "$updated_json"
    }

    # Processing --set parameter
    set_procedure() {
      local path="$1"

      # Basic validation
      if validate_genpath "$param"; then
        echo "Copying to local cache..."
        nix copy --from https://prod-cache.vedenemo.dev "$path"

        echo "Setting the new system profile..."
        sudo nix-env -p /nix/var/nix/profiles/system --set "$path"
        echo "System profile successfully updated to $path."
      else
        echo "Error: Invalid parameter. Please provide a valid Nix store path matching the required pattern."
        exit 1
      fi
    }

    # Main script logic
    case "$1" in
      --get)
        get_procedure
        ;;
      --set)
        if [[ -z "$2" ]]; then
          echo "Error: --set requires a parameter."
          exit 1
        fi
        set_procedure "$2"
        ;;
      *)
        echo "Usage: $0 --get | --set <generation_path>"
        exit 1
        ;;
    esac
  '';
in
{
  networking.hostName = lib.mkDefault "ghaf-host";
  networking.hosts = lib.foldl' (acc: entry:
    acc // { "${entry.ip}" = entry.hostname; }
  ) {} updateSources.updateSourcesEntries;

  # Overlays should be only defined for host, because microvm.nix uses the
  # pkgs that already has overlays in place. Otherwise the overlay will be
  # applied twice.
  nixpkgs.overlays = [ (import ../../overlays/custom-packages) ];
  imports = [
    # To push logs to central location
    ../common/logging/client.nix
  ];
  environment.systemPackages = [ updateScript pkgs.jq ];
}
