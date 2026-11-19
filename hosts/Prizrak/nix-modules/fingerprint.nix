# Experimental Goodix GF511 fingerprint support (27c6:5110) for Huawei MateBook D.
#
# The sensor is NOT supported by upstream libfprint:
#   https://gitlab.freedesktop.org/libfprint/wiki/-/wikis/Unsupported-Devices
# This module swaps in the community fork that adds the goodixtls511 driver
# (branch goodixtls-upstream-mr of buxel/libfprint, see
# https://github.com/buxel/libfprint-27c6-5110), and provides the one-shot
# firmware provisioning tool `goodix-provision-5110` (from goodix-fp-dump).
#
# After the rebuild the sensor is detected as "Goodix TLS Fingerprint Sensor 511".
# If the sensor is not provisioned yet (fresh device), run once as root:
#   sudo goodix-provision-5110    # flashes GF_ST411SEC_APP_12117 firmware
# (on this laptop the firmware/PSK were already in place, so this was not needed).
# Then enroll a finger:
#   fprintd-enroll -f right-index-finger
# and verify:
#   fprintd-verify -f right-index-finger
{
  lib,
  pkgs,
  ...
}:
let
  # Python environment for the provisioning tool.
  pythonEnv = pkgs.python3.withPackages (p: with p; [
    pyusb
    crcmod
    pycryptodome
    crccheck
    python-periphery
    spidev
  ]);

  goodixFirmware = pkgs.fetchFromGitHub {
    owner = "goodix-fp-linux-dev";
    repo = "goodix-firmware";
    rev = "7b9a828d1d14dee587d9c900505233188c23a92d";
    hash = "sha256-OtavEXVMij9MTTNrWSkix5oXyfghuTWlEHKDclJHR2o=";
  };

  # One-shot firmware provisioning tool for the GF511 sensor.
  goodix-fp-dump = pkgs.stdenv.mkDerivation {
    pname = "goodix-fp-dump";
    version = "unstable-2023-05-30";

    src = pkgs.fetchFromGitHub {
      owner = "goodix-fp-linux-dev";
      repo = "goodix-fp-dump";
      rev = "cc43bb3b3154a0bccc0412ae024013c7e1923139";
      hash = "sha256-JqY0kRMm//xsmcpGOkUjUD/WNqTZM8oKGNxir/Hkyfg=";
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      mkdir -p $out/share/goodix-fp-dump $out/bin
      cp -r $src/. $out/share/goodix-fp-dump
      rm -rf $out/share/goodix-fp-dump/firmware
      ln -s ${goodixFirmware} $out/share/goodix-fp-dump/firmware
      makeWrapper ${pythonEnv}/bin/python3 $out/bin/goodix-provision-5110 \
        --chdir $out/share/goodix-fp-dump \
        --add-flags run_5110.py
    '';
  };
in
{
  nixpkgs.overlays = [
    (final: prev: {
      # libfprint fork with the goodixtls511 driver (Goodix GF511, 27c6:5110).
      libfprint = prev.libfprint.overrideAttrs (old: {
        version = "1.94.9-goodixtls511";
        src = final.fetchFromGitHub {
          owner = "buxel";
          repo = "libfprint";
          rev = "8c3674092ed29bfc6bf0fcf73b24fd821393508c";
          hash = "sha256-Rygz4tjdQnd0qhxm0NTiHip7gp5qPhFEPXN93oJY7kU=";
        };
        # Docs are disabled, so the devdoc output is not produced.
        outputs = [ "out" ];
        mesonFlags = old.mesonFlags ++ [
          "-Dgoodixtls=enabled"
          # The fork's test harness / introspection don't build under nixpkgs'
          # build environment and are not needed at runtime (same as the AUR pkg).
          "-Dinstalled-tests=false"
          "-Dintrospection=false"
          "-Ddoc=false"
        ];
        buildInputs = old.buildInputs ++ [ final.gnutls ];
        # The fork targets libfprint 1.94.9; skip the upstream post-install test run.
        doInstallCheck = false;
      });
    })
  ];

  services.fprintd.enable = true;

  environment.systemPackages = [ goodix-fp-dump ];
}
