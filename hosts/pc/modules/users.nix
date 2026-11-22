# Host identity, networking and the main user account for the generic PC host.
# scripts/nixinstall rewrites the hostname and injects the user password here.
{
  config,
  pkgs,
  username,
  ...
}:
{
  networking.hostName = "nixos"; # nixinstall rewrites this

  networking.networkmanager.enable = true;

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    extraGroups = [
      "wheel"
      "networkmanager"
    ];
  };
}
