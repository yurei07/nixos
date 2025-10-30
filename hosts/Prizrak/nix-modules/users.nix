{
  config,
  pkgs,
  username,
  ...
}:
{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  networking.nameservers = [ "8.8.8.8" "1.1.1.1" ];

  time.timeZone = "Europe/Berlin";

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
}
