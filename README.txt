# wine-manager
Manages multiple Wine versions and bottles so they can be used simultaneously. Also creates an integrated customizable XDG menu that can be used to hide or reveal various bottle menus.

This is just the initial upload of the Wine Manager code so that those who are interested can peruse it.

It's a bit complicated to setup, and requires mergerfs to virtualize the ~/Desktop, ~/.config/menus, ~/.local/share/applications, ~/.local/share/desktop-directories, ~/.local/share/icons. and ~/.local/share/mime directories.

It also requires a  systemd service to mount the virtualized directories at boot. The sample file "mergerfs_bootmount_username.service" can be used by replacing "username" with your username. However further instructions are required to setup the required directory structure, and I'll add those soon.

The whole system is quite complicated, but here's an initial description of the files:

winemgr.sh, winemgr_vars.sh                               - The main Wine Manager files

token_parser.sh                                           - A full fledged token parser.

key_file.sh, key_file_vars.sh                             - Code to enable the transparent storage of key/value     pairs.

standard_vars.sh, standard_main.sh, standard_functions.sh - A plethora of standard functions I use for a lot of things.

mergerfs_bootmount_username.service                       - A sample systemd file used to create the virtualized XDG
                                                            menu file system.
                                                            
mda.sh, mada_vars.sh                                      - Arbitrary multi-dimensional array functions. Note these 
                                                            are not yet used in the existing version, and are being
                                                            integrated into the next version. They are just included
                                                            for completeness.
