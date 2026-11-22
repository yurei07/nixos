# System fonts used by terminal apps and the editor.
{ pkgs, ... }:
{
	fonts.packages = with pkgs; [
		inter
		noto-fonts
		noto-fonts-color-emoji
		nerd-fonts.jetbrains-mono
		material-symbols
	];
}
