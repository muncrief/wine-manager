# wine-manager
Manages multiple Wine versions and bottles so they can be used simultaneously. Also creates an integrated customizable XDG menu that can be used to hide or reveal various bottle menus.

This is just the initial upload of the Wine Manager code so that those who are interested can peruse it.

It's a bit complicated to setup, and requires mergerfs to virtualize to virtualize the ~/Desktop, ~/.config/menus, ~/.local/share/applications, ~/.local/share/desktop-directories, ~/.local/share/icons. and ~/.local/share/mime directories.

It also requires a  systemd service to mount the virtualized directories at boot. The sample file "mergerfs_bootmount_username.service" can be used by replacing "username" with your username. However further instructions are required to setup the required directory structure, and I'll add those soon.
