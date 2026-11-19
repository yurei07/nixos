# Laptop-specific settings for Huawei MateBook D (NBLK-WAX9X):
# - NVMe SSD, 8 GB RAM, RTL8822CE Wi-Fi, Goodix fingerprint, ACP3x audio.
{
  lib,
  config,
  ...
}:
{
  # Microcode + firmware (Wi-Fi/BT/camera) — keeps drivers up to date.
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Firmware/driver updates through the Linux Vendor Firmware Service
  # (BIOS/UEFI, SSD firmware, etc.): `fwupdmgr refresh && fwupdmgr update`.
  services.fwupd.enable = true;

  # Power management (supports "power-saver / balanced / performance" modes).
  services.power-profiles-daemon.enable = true;
  services.logind = {
    # Close lid on battery / AC -> suspend; on dock -> ignore.
    lidSwitch = "suspend";
    lidSwitchDocked = "ignore";
  };

  # Wi-Fi power saving.
  networking.networkmanager.wifi.powersave = true;

  # Maintenance for the NVMe SSD.
  services.fstrim.enable = true;

  # 8 GB RAM: compressed zram swap before hitting the SSD swap partition.
  zramSwap = {
    enable = true;
    memoryPercent = 50;
  };

  # Goodix fingerprint sensor (27c6:5110) for login / sudo (via PAM).
  services.fprintd.enable = true;
}
