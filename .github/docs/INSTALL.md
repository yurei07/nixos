# Fresh install
 
## Requirements
- NixOS already installed (minimal ISO is fine)
- Flakes enabled: `nix.settings.experimental-features = [ "nix-command" "flakes" ];`
## Steps
 
1. Clone the repository:
```bash
sudo git clone https://github.com/yurei07/nixos /etc/nixos
cd /etc/nixos
```
 
2. Generate hardware-configuration.nix for the new machine (if installing on new hardware):
```bash
sudo nixos-generate-config --show-hardware-config > hosts/<host>/hardware-configuration.nix
```
 
3. Find and replace every spot that needs adjusting for the new user/machine:
```bash
rg "CHANGEME" /etc/nixos
```
 
4. Build and switch:
```bash
sudo nixos-rebuild switch --flake /etc/nixos#<host>
```
 
5. Reboot to pick up all system services:
```bash
sudo reboot
```
 
## Updating later
 
```bash
cd /etc/nixos
nix flake update        # update flake.lock (all inputs)
sudo nixos-rebuild switch --flake .#<host>
```
 
Update a single input:
```bash
nix flake lock --update-input nixpkgs
```
 

