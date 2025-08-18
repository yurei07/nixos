{inputs, pkgs,  ...}:
{
  imports = [inputs.nixcord.homeModules.nixcord];

  programs.nixcord = {
    enable = true;
    config = {
      useQuickCss = true;
      themeLinks = [
	      "https://refact0r.github.io/midnight-discord/build/midnight.css"
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
