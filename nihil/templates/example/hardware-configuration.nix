{ lib, modulesPath, ... }:
{
	imports = [ (modulesPath + "/profiles/qemu-guest.nix") ];

	boot.initrd.availableKernelModules = [ "ahci" "xhci_pci" "virtio_pci" "virtio_blk" "sr_mod" ];

	fileSystems."/" = { device = "/dev/disk/by-label/nixos"; fsType = "btrfs"; options = [ "subvol=@" ]; };
	fileSystems."/boot" = { device = "/dev/disk/by-label/BOOT"; fsType = "vfat"; options = [ "umask=0077" ]; };

	nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
}
