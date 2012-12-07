You can add custom scripts and menu entries for NookManager here.

To add a custom menu, create a file named "custom" in the "menu" folder.  Your menu will be available under the "More | Custom" screen in NookManager.  A sample file is provided.

To run a script automatically after the rooting process, create a file named "post_root" in the "scripts" folder.

If you are creating files on Windows, be sure to save them with unix lineendings.  Files with windows lineedings will not work!

NookManager caches the scripts and menus when the system is booted, so any changes your make will not be available until you reboot your nook or until you manually restart NookManager.  To manually restart, connect to ADB shell and run "stop system_ready && start system_ready"  This will refresh the cache from the scdard and restart the NookManager interface.