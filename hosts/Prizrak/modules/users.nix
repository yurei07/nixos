# Base host identity, networking and the main user account.
{
  config,
  pkgs,
  username,
  ...
}:
{
  networking.hostName = "nixos";
  networking.networkmanager.enable = true;

  time.timeZone = "Europe/Berlin";

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [
      "wheel"
      "networkmanager"
      "docker"
    ];
  };
}
