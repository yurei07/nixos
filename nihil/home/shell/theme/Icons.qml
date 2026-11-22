pragma Singleton

import Quickshell

Singleton {
    function g(cp: int): string { return String.fromCodePoint(cp); }

    readonly property string nix: g(0xF1105)
    readonly property string weatherClear: g(0xF0599)
    readonly property string weatherNight: g(0xF0594)
    readonly property string weatherPartly: g(0xF0595)
    readonly property string weatherNightPartly: g(0xF0F31)
    readonly property string weatherCloudy: g(0xF0590)
    readonly property string weatherFog: g(0xF0591)
    readonly property string weatherDrizzle: g(0xF0597)
    readonly property string weatherRain: g(0xF0596)
    readonly property string weatherShowers: g(0xF0F33)
    readonly property string weatherSnow: g(0xF0598)
    readonly property string weatherStorm: g(0xF067E)
    readonly property string wifiOff: g(0xF05AA)
    readonly property string wifiOn: g(0xF05A9)
    readonly property var wifiLevels: [g(0xF092F), g(0xF091F), g(0xF0922), g(0xF0925), g(0xF0928)]
    readonly property string ethernet: g(0xF0200)
    readonly property string lock: g(0xF033E)
    readonly property string check: g(0xF012C)
    readonly property string refresh: g(0xF0450)
    readonly property string cog: g(0xF0493)
    readonly property string btOff: g(0xF00B2)
    readonly property string btOn: g(0xF00AF)
    readonly property string btConnected: g(0xF00B1)
    readonly property string battery: g(0xF007A)
    readonly property string batteryCharging: g(0xF0085)
    readonly property string volLow: g(0xF057F)
    readonly property string volMid: g(0xF0580)
    readonly property string volHigh: g(0xF057E)
    readonly property string volMute: g(0xF075F)
    readonly property string mic: g(0xF036C)
    readonly property string micOff: g(0xF036D)
    readonly property string shot: g(0xF0100)
    readonly property string record: g(0xF044A)
    readonly property string stop: g(0xF04DB)
    readonly property string brightness: g(0xF00E0)
    readonly property string play: g(0xF040A)
    readonly property string pause: g(0xF03E4)
    readonly property string next: g(0xF04AD)
    readonly property string prev: g(0xF04AE)
    readonly property string power: g(0xF0425)
    readonly property string restart: g(0xF0709)
    readonly property string sleep: g(0xF04B2)
    readonly property string logout: g(0xF0343)
    readonly property string bell: g(0xF009A)
    readonly property string bellOff: g(0xF009B)
    readonly property string night: g(0xF0594)
    readonly property string close: g(0xF0156)
    readonly property string search: g(0xF0349)
    readonly property string calculator: g(0xF00EC)
    readonly property string image: g(0xF02E9)
    readonly property string speaker: g(0xF04C3)
    readonly property string headphones: g(0xF02CB)
    readonly property string chevron: g(0xF0142)
    readonly property string terminal: g(0xF018D)
    readonly property string plus: g(0xF0415)
    readonly property string coffee: g(0xF0176)
    readonly property string chevronLeft: g(0xF0141)
    readonly property string copy: g(0xF018F)
    readonly property string broom: g(0xF00E2)
    readonly property string download: g(0xF01DA)
    readonly property string pencil: g(0xF03EB)
    readonly property string swap: g(0xF04E1)
    readonly property string paste: g(0xF0192)
    readonly property string file: g(0xF0214)
    readonly property string video: g(0xF0567)
    readonly property string open: g(0xF03CC)

    function volume(level: real, muted: bool): string {
        if (muted || level <= 0) return volMute;
        return level < 0.34 ? volLow : level < 0.67 ? volMid : volHigh;
    }

    function wifi(signal: int): string {
        return wifiLevels[Math.max(0, Math.min(4, Math.round(signal / 25)))];
    }
}
