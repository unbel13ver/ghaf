# LabWC window compositor/desktop environment

From LabWC's [github project](https://github.com/labwc/labwc) [frontpage](https://labwc.github.io/):

>Labwc is a wlroots-based window-stacking compositor for wayland, inspired by openbox.
>
>It is light-weight and independent with a focus on simply stacking windows well and rendering some window decorations. It takes a no-bling/frills approach and says no to features such as animations. It relies on clients for panels, screenshots, wallpapers and so on to create a full desktop environment.
>
>Labwc tries to stay in keeping with wlroots and sway in terms of general approach and coding style.
>
>Labwc has no reliance on any particular Desktop Environment, Desktop Shell or session. Nor does it depend on any UI toolkits such as Qt or GTK.


LabWC is configured as a module in Ghaf. To take it in use, use the configuration option `profiles.graphics.compositor = "labwc"`;
Or just uncomment the corresponding line in [guivm.nix](../../modules/virtualization/microvm/guivm.nix) file.
