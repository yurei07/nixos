# Arduino development: udev rules so boards are detected instantly with the
# right permissions. The IDE and CLI are user packages (home.nix).
{ config, pkgs, ... }:
{
	# dialout is the group NixOS udev rules give serial devices to
	users.users.${config.nihil.user.name}.extraGroups = [ "dialout" ];

	services.udev.extraRules = ''
		# Arduino boards (Uno, Nano, Mega, Micro, Leonardo, MKR...)
		SUBSYSTEM=="tty", ATTRS{idVendor}=="2341", MODE="0660", GROUP="dialout", TAG+="uaccess"
		# CH340/CH341 clones (most third-party Nanos)
		SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", MODE="0660", GROUP="dialout", TAG+="uaccess"
		# FTDI (older clones, some Teensy-like boards)
		SUBSYSTEM=="tty", ATTRS{idVendor}=="0403", MODE="0660", GROUP="dialout", TAG+="uaccess"
		# CP210x (ESP32 dev boards, many clones)
		SUBSYSTEM=="tty", ATTRS{idVendor}=="10c4", MODE="0660", GROUP="dialout", TAG+="uaccess"
		# RP2040 / Pico serial
		SUBSYSTEM=="tty", ATTRS{idVendor}=="2e8a", MODE="0660", GROUP="dialout", TAG+="uaccess"
		# ESP8266 / CH9102
		SUBSYSTEM=="tty", ATTRS{idVendor}=="1a86", ATTRS{idProduct}=="ea60", MODE="0660", GROUP="dialout", TAG+="uaccess"
	'';
}
