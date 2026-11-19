# Laptop-specific power, firmware and maintenance settings.
{
  lib,
  config,
  ...
}:
{
  # Microcode + firmware (Wi-Fi/BT/camera).
  hardware.cpu.amd.updateMicrocode = true;
  hardware.enableRedistributableFirmware = true;

  # Firmware/driver updates through the Linux Vendor Firmware Service:
  # `fwupdmgr refresh && fwupdmgr update`.
  services.fwupd.enable = true;

  # Power management (power-saver / balanced / performance).
  services.power-profiles-daemon.enable = true;
  services.logind = {
    settings.Login = {
      HandleLidSwitch = "suspend";
      HandleLidSwitchDocked = "ignore";
    };
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
