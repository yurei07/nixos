{
  config,
  lib,
  pkgs,
  ...
}:
{
  environment.systemPackages = [
    (pkgs.wrapOBS {
      plugins = [
        pkgs.obs-studio-plugins.obs-vaapi
        pkgs.gst_all_1.gstreamer
      ];
    })
    pkgs.gst_all_1.gstreamer
    pkgs.obs-studio-plugins.obs-vaapi
  ];
  boot.extraModulePackages = with config.boot.kernelPackages; [
    v4l2loopback
  ];
  boot.extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=1 card_label="OBS Cam" exclusive_caps=1
  '';
  security.polkit.enable = true;
}
