# fastfetch in the Nothing OS style: braille dot-matrix NixOS logo, Lettera-style
# uppercase section labels, white values and the single red accent on the keys.
{ pkgs, ... }: {
  xdg.configFile."fastfetch/config.jsonc".text = ''
    {
      "$schema": "https://github.com/fastfetch-cli/fastfetch/raw/dev/doc/json_schema.json",
      "logo": {
          "type": "file",
          "source": "/etc/nixos/modules/tui/fastfetch/logo/nixos-dots.txt",
          "padding": {
              "top": 2,
              "left": 2,
              "right": 4
          }
      },
      "display": {
          "separator": "  "
      },
      "modules": [
          "break",
          {
              "type": "custom",
              "format": "\u001b[90m  S Y S T E M\u001b[0m"
          },
          {
              "type": "host",
              "key": "\u001b[31m󰌢\u001b[0m  host",
              "keyColor": "red"
          },
          {
              "type": "os",
              "key": "\u001b[31m󰣇\u001b[0m  os"
          },
          {
              "type": "kernel",
              "key": "\u001b[31m󰘳\u001b[0m  kernel"
          },
          {
              "type": "uptime",
              "key": "\u001b[31m󰅐\u001b[0m  uptime"
          },
          {
              "type": "packages",
              "key": "\u001b[31m󰏖\u001b[0m  packages"
          },
          "break",
          {
              "type": "custom",
              "format": "\u001b[90m  L O O K\u001b[0m"
          },
          {
              "type": "wm",
              "key": "\u001b[31m󰖰\u001b[0m  wm"
          },
          {
              "type": "shell",
              "key": "\u001b[31m󰆍\u001b[0m  shell"
          },
          {
              "type": "terminal",
              "key": "\u001b[31m󰆝\u001b[0m  terminal"
          },
          {
              "type": "theme",
              "key": "\u001b[31m󰉼\u001b[0m  theme"
          },
          {
              "type": "cursor",
              "key": "\u001b[31m󰇀\u001b[0m  cursor"
          },
          "break",
          {
              "type": "custom",
              "format": "\u001b[90m  H A R D W A R E\u001b[0m"
          },
          {
              "type": "cpu",
              "key": "\u001b[31m󰻠\u001b[0m  cpu"
          },
          {
              "type": "gpu",
              "key": "\u001b[31m󰍹\u001b[0m  gpu"
          },
          {
              "type": "memory",
              "key": "\u001b[31m󰑭\u001b[0m  memory"
          },
          {
              "type": "swap",
              "key": "\u001b[31m󰓡\u001b[0m  swap"
          },
          {
              "type": "disk",
              "key": "\u001b[31m󰋊\u001b[0m  disk"
          },
          {
              "type": "battery",
              "key": "\u001b[31m󰁹\u001b[0m  battery",
              "showChargeType": true
          },
          "break",
          {
              "type": "custom",
              "format": "\u001b[90m  N E T W O R K\u001b[0m"
          },
          {
              "type": "localip",
              "key": "\u001b[31m󰩟\u001b[0m  ip"
          },
          {
              "type": "wifi",
              "key": "\u001b[31m󰤨\u001b[0m  wifi"
          },
          "break"
      ]
    }
  '';
}
