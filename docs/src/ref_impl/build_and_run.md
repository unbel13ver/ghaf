<!--
    Copyright 2022-2023 TII (SSRC) and the Ghaf contributors
    SPDX-License-Identifier: CC-BY-SA-4.0
-->

# Build and Run

The canonical URL for the upstream Ghaf git repository is <https://github.com/tiiuae/ghaf>. To try Ghaf, you can build it from the source.

Our supported targets are the following:

| Device           | Architecture     |
|---               |---               |
| Generic Intel    | x86              |
| NVIDIA Jetson AGX Orin  | AArch64   |
| NXP i.MX 8QM-MEK | AArch64          |

Scope of target support is updated with development progress.

## Building Ghaf Image

Before you begin, follow the basic device-independent steps:

* Clone the git repository <https://github.com/tiiuae/ghaf>.
* Ghaf uses a Nix flake approach to build the framework targets, make sure to:
  * Install Nix or full NixOS if needed: <https://nixos.org/download.html>.
  * Enable flakes: <https://nixos.wiki/wiki/Flakes#Enable_flakes>.  
    To see all Ghaf supported outputs, type `nix flake show`.
  * Set up an AArch64 remote builder: <https://nixos.org/manual/nix/stable/advanced-topics/distributed-builds.html>.
> [Cross-compilation](https://tiiuae.github.io/ghaf/build_config/cross_compilation.html) support is currently under development and not available for the building process.
---


### Running Ghaf Image for x86 VM (ghaf-host)

For Intel NUC, run the `nix run .#packages.x86_64-linux.vm` command.

This creates `ghaf-host.qcow2` copy-on-write overlay disk image in your current directory. If you do unclean shutdown for the QEMU VM, you might get weird errors the next time you boot. Simply removing `ghaf-host.qcow2` should be enough. To cleanly shut down the VM, from the menu bar of the QEMU Window, click Machine and then Power Down.


---

### Ghaf Image for NVIDIA Jetson Orin AGX
#### Flashing NVIDIA Jetson Orin AGX
For the fresh device flashing bootloader firmware is required. 
1. Run
  ```
  nix build github:tiiuae/ghaf#nvidia-jetson-orin-debug-flash-script
  ```
  command which builds Ghaf image, bootloader firmware and prepares the flashing script. Say `yes` to all script questions. The building process takes around 1,5 hours. 
2. Set up the following connections:
   1. Connect the board to a power supply with a USB-C cable.
   2. Connect a Linux laptop to the board with the USB-C cable.
   3. Connect the Linux laptop to the board with a Micro-USB cable.
   > For more information on the board's connections details, see the [Hardware Layout](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/developer_kit_layout.html) section of the Jetson AGX Orin Developer Kit User Guide.
3. After the build is completed, put the board in recovery mode (for more information, see the [Force Recovery Mode](https://developer.nvidia.com/embedded/learn/jetson-agx-orin-devkit-user-guide/howto.html#force-recovery-mode) section in the Jetson AGX Orin Developer Kit User Guide), and run the flashing script: 
  ```
  sudo ~/result/bin/flash-ghaf-host
  ```
  If you got the error message `ERROR: might be timeout in USB write.`, reboot the device and put it in recovery mode again. Check with the `lsusb` command if your computer can recognize the board, and run the flash script again.
4. Power cycle the device after flashing is done.

#### Building and running Ghaf image
After the latest firmware is in place, it is possible to use simplified process by building only Ghaf disk image and running it from external media.
1. Run 
  ```
  nix build github:tiiuae/ghaf#nvidia-jetson-orin-debug
  ``` 
  to build the target image;
2. After the build is completed, prepare a USB boot media with the target image you built: 
  ```
  dd if=./result/nixos.img of=/dev/<YOUR_USB_DRIVE> bs=32M
  ```

---

### Ghaf Image for NXP i.MX 8QM-MEK

In the case of i.MX8, Ghaf deployment contains of:

* creating a bootable SD card with a first-stage bootloader (Tow-Boot)  
and  
*  creating USB media with the Ghaf image.


1. To build and flash [**Tow-Boot**](https://github.com/tiiuae/Tow-Boot) bootloader:  

  ```
    $ git clone https://github.com/tiiuae/Tow-Boot.git && cd Tow-Boot
    $ nix-build -A imx8qm-mek
    $ sudo dd if=result/ shared.disk-image.img of=/dev/<SDCARD>
  ```

2. To build and flash the Ghaf image:
   1. Run the `nix build .#packages.aarch64-linux.imx8qm-mek-release` command.
   2. Prepare the USB boot media with the target HW image you built: `dd if=./result/nixos.img of=/dev/<YOUR_USB_DRIVE> bs=32M`.
   
3. Insert an SD card and USB boot media into the board and switch the power on.

> [Cross-compilation](https://tiiuae.github.io/ghaf/build_config/cross_compilation.html) support is currently under development and not available for the building process.
