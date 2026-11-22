# Placeholder hardware configuration; scripts/nixinstall regenerates it with
# nixos-generate-config on the target machine.
{ modulesPath, ... }:
{
  imports = [ (modulesPath + "/installer/scan/not-detected.nix") ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "ahci"
    "xhci_pci"
    "usbhid"
    "usb_storage"
    "sd_mod"
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos-root";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/nixos-esp";
    fsType = "vfat";
    options = [ "fmask=0022" "dmask=0022" ];
  };
}
