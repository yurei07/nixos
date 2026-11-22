# session-env.nix by poligle

{
	# X through XWayland when a Qt brought along has no Wayland plugin.
	QT_QPA_PLATFORM = "wayland;xcb";
	QT_QPA_PLATFORMTHEME = "qt6ct";
	QT_STYLE_OVERRIDE = "Fusion";
	_JAVA_AWT_WM_NONREPARENTING = "1";
}
