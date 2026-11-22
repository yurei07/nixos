# vm.nix by poligle

# The example machine in a window, NIHIL as it comes: nix run .#vm. Nothing of the computer it
# runs on shows in it but the folder it was run from, at /mnt/nihil, where the docs' pictures
# can be taken and kept. Only for the VM: the example machine itself stays as it is.
{ config, lib, pkgs, ... }:
let
    user = config.nihil.user.name;

    # Something playing, as there is in every picture with music: a tune made here, on a loop,
    # with no cover. The VM's sound goes nowhere, so it plays unheard.
    tune = pkgs.runCommand "ex-nihilo.ogg" { nativeBuildInputs = [ pkgs.ffmpeg-headless ]; }
    ''
        note='if(eq(mod(floor(t*4),8),0),220,if(eq(mod(floor(t*4),8),1),261.63,if(eq(mod(floor(t*4),8),2),329.63,if(eq(mod(floor(t*4),8),3),392,if(eq(mod(floor(t*4),8),4),440,if(eq(mod(floor(t*4),8),5),392,if(eq(mod(floor(t*4),8),6),329.63,261.63)))))))'
        wave="0.16*sin(2*PI*55*t)*(0.7+0.3*sin(2*PI*0.125*t))+0.22*sin(2*PI*$note*t)*exp(-6*mod(t,0.25))"
        ffmpeg -hide_banner -loglevel error -f lavfi -i "aevalsrc='$wave':s=44100:d=240" -ac 2 \
            -c:a libvorbis -q:a 3 -metadata title="ex nihilo" -metadata artist="NIHIL" "$out"
    '';
    player = pkgs.mpv.override { scripts = [ pkgs.mpvScripts.mpris ]; };
in
{
    virtualisation.vmVariant =
    {
        virtualisation =
        {
            memorySize = 8192;
            cores = 4;
            diskSize = 8192;
            # Hyprland draws with GL: virtio-gpu with virgl, shown by GTK, which scales it to its
            # window. The screen is the site's pictures', 1920x1200.
            qemu.options =
            [
                "-vga none"
                "-device virtio-vga-gl,xres=1920,yres=1200"
                "-display gtk,gl=on,zoom-to-fit=on"
                # A sound card, for PipeWire and the visualiser, whose sound goes nowhere.
                "-audiodev none,id=nihil"
                "-device intel-hda"
                "-device hda-output,audiodev=nihil"
            ];
            sharedDirectories.nihil =
            {
                source = ''"''${NIHIL_VM_SOURCE:-$PWD}"'';
                target = "/mnt/nihil";
            };
        };

        # The mode, not whatever size the window is resized to.
        nihil.outputs.Virtual-1 = { width = 1920; height = 1200; mode = "1920x1200@60"; };

        # No installer asked for a password, and the session starts by itself once at boot.
        users.users.${user}.initialPassword = "nihil";
        services.greetd.settings.initial_session =
        {
            inherit user;
            command = "${config.programs.uwsm.package}/bin/uwsm start -e -D Hyprland hyprland.desktop";
        };

        environment.systemPackages = [ player ];
        systemd.user.services.nihil-vm-tune =
        {
            description = "ex nihilo, on a loop, for the pictures";
            wantedBy = [ "graphical-session.target" ];
            partOf = [ "graphical-session.target" ];
            after = [ "graphical-session.target" ];
            serviceConfig.ExecStart = "${lib.getExe player} --no-video --no-terminal --loop-file=inf ${tune}";
        };
    };
}
