{ pkgs, inputs, config, ... }:
let
  script-rebuild = pkgs.writeTextFile {
    name = "rebuild-cache";
    text = ''
      #!${pkgs.bash}/bin/bash
      PATH=$PATH:${pkgs.jq}/bin:${pkgs.git}/bin:${pkgs.findutils}/bin:${config.nix.package}/bin:${pkgs.coreutils-full}/bin
      cd $(mktemp -d)
      (git clone https://github.com/NazariiPalahnii/nixos --depth 1 & git clone https://github.com/DADA30000/dotfiles --depth 1)
      for i in */; do
        (cd $i; nix flake show --json | jq '.nixosConfigurations|keys[]'| xargs -I {} nix build .#nixosConfigurations.{}.config.system.build.toplevel --max-jobs 32 --max-substitution-jobs 32)
      done 
      rm -rf $PWD 
    '';
    executable = true;
  };
in
{
  imports = [ # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  zramSwap.enable = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader.timeout = 0;
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "server"; # Define your hostname.

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager = {
    enable = true;
    wifi.backend = "iwd";
  };

  services.nix-serve = {
    enable = true;
    package = pkgs.nix-serve-ng;
    openFirewall = true;
  };

  nix.settings = {
    auto-optimise-store = true;

    # Enable flakes
    experimental-features = [
      "nix-command"
      "flakes"
    ];

  };

  nix.gc = {
    automatic = true;
    dates = "monthly";
    options = "--delete-older-than 7d";
  };

  swapDevices = [
    { label = "swap"; }
  ];

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=root"
      "compress-force=zstd"
    ];
  };

  fileSystems."/copyparty" = {
    device = "/dev/disk/by-label/data";
    fsType = "btrfs";
    options = [
      "subvol=copyparty"
      "compress-force=zstd"
    ];
  };

  fileSystems."/nix" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=nix"
      "compress-force=zstd"
    ];
  };

  fileSystems."/home" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "btrfs";
    options = [
      "subvol=home"
      "compress-force=zstd"
    ];
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-label/boot";
    fsType = "vfat";
  };

  services.copyparty = {
    enable = true;
    package = inputs.copyparty.checks.${pkgs.system}.copyparty-full;
    settings = {
      i = "0.0.0.0";
      no-reload = true;
      p = [ 80 8080 ];
      ah-alg = "argon2";
      usernames = true;
      reflink = true;
      dedup = true;
      magic = true;
      ftp = 21;
    };
    accounts = {
      prizrak.passwordFile = "${pkgs.writeText "prizrak_pass" "+3Wu0D453mzpG7CTgB5mml4UBLYfaNKju"}";
      sanic.passwordFile = "${pkgs.writeText "sanic_pass" "+EnF0Iny3Dz4oavfIrdmesBfoZd4mjgYc"}";
    };
    volumes = {
      # create a volume at "/" (the webroot), which will
      "/" = {
        # share the contents of "/srv/copyparty"
        path = "/copyparty";
        # see `copyparty --help-accounts` for available options
        access = {
          # everyone gets read-access, but
          r = "*";
          # users "ed" and "k" get read-write
          rw = [ "prizrak" "sanic" ];
        };
        # see `copyparty --help-flags` for available options
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          e2t = true;
        };
      };
      "/prizrak" = {
        path = "/copyparty/prizrak";
        access = {
          r = "prizrak";
          rw = "prizrak";
        };
        flags = {
          # "fk" enables filekeys (necessary for upget permission) (4 chars long)
          fk = 4;
          # scan for new files every 60sec
          scan = 60;
          # volflag "e2d" enables the uploads database
          e2d = true;
          # "d2t" disables multimedia parsers (in case the uploads are malicious)
          e2t = true;
        };
      };
    };
  };

  # Set your time zone.
  time.timeZone = "Europe/Berlin";

  # Select internationalisation properties.
  i18n.defaultLocale = "ru_RU.UTF-8";
  console = {
    font = "cyr-sun16";
    keyMap = "ru";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.server = {
    isNormalUser = true;
    hashedPassword = "$y$j9T$Abrbp.brirPY8e0qmfhlr0$xbpA8FUyJl4jvgpWPCYaKIruPJNBcqGXPpFPrJwX9a3";
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
  };

  environment.systemPackages = with pkgs; [
    neovim
    wget
    curl
  ];

  nix.settings = {
    auto-optimise-store = true;
    substituters = [ "https://hyprland.cachix.org" ];
    trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
  };

  services.openssh.enable = true;

  boot.initrd.systemd.enable = true;

  networking.firewall.allowedTCPPorts = [ 80 8080 21 22 ];
  networking.firewall.allowedUDPPorts = [ 80 8080 21 22 ];

  home-manager.users.server = {
    imports = [
      ../../modules/tui/neovim
      ../../modules/tui/kitty
      ../../modules/tui/zsh
      ../../modules/tui/nh
    ];
    systemd.user = {
      timers.trigger-rebuild = {
          Unit = {
            Description = "Timer that triggers cache rebuild every hour";
          };
          Timer = {
            OnBootSec = 10;
            OnUnitActiveSec = "1h";
            Unit = "rebuild.service";
          };
          Install = {
            WantedBy = [ "timers.target" ];
          };
        };
      services.rebuild = {
        Service.ExecStart = "${script-rebuild}";
      };
    };
    home.stateVersion = "25.11";
  };

  system.stateVersion = "25.11";

}

