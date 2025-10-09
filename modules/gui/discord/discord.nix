{inputs, pkgs,  ...}:
let 
  color = import ../../../materials/themes {};
in
{
  imports = [inputs.nixcord.homeModules.nixcord];

  programs.nixcord = {
    enable = true;
    quickCss = '' 
      :root {
        --text-0: ${color.base00};
        --text-1: ${color.base07};
        --text-2: ${color.base06};
        --text-3: ${color.base05};
        --text-4: ${color.base04};
        --text-5: ${color.base03};

        --bg-1: ${color.base02};
        --bg-2: ${color.base01};
        --bg-3: ${color.base00};
        --bg-4: ${color.base01};

        --accent-1: ${color.base0D};
        --accent-2: ${color.base0D};
        --accent-3: ${color.base0D};
        --accent-4: ${color.base0D};
        --accent-5: ${color.base0D};
        --accent-new: ${color.base0B};

        --border-thickness: 1px;
        --divider-thinckness: 2px;
      }
    '';
    config = {
      useQuickCss = true;
      themeLinks = [
        "https://refact0r.github.io/system24/build/system24.css"
      ];

      plugins = {
        noBlockedMessages.enable = true;
	      readAllNotificationsButton.enable = true;
	      biggerStreamPreview.enable = true;
	      gameActivityToggle.enable = true;
	      fakeNitro.enable = true;
	      clientTheme.enable = true;
      };

      frameless = true;
    };
  };
}
