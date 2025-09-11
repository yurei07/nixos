{config, pkgs, ...}:
{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin"; 

  users.users.laptop_Prizrak = {
    isNormalUser = true;
    home = "/home/laptop_Prizrak";
    extraGroups = ["wheel" "networkmanager" ];
    hashedPassword = "$6$IHu2UngoxSM9bgnM$nQZiygikiLgh3UOODFMXikzDNw68PFsr0QcrNMvquOVER/nm4lVdUzRAPcYYVNYV/.JcehuUJXOyzYYad/nni.";
  };
}
