# shaders.nix by poligle

{ pkgs }:
pkgs.runCommand "nihil-glass-shaders" { } ''
	qsb=$(find -L ${pkgs.qt6.qtshadertools} -name qsb -type f | head -n 1)
	[ -n "$qsb" ] || { echo "qsb not found in qtshadertools" >&2; exit 1; }
	mkdir -p $out
	for shader in ${../home/shell/shaders}/*.vert ${../home/shell/shaders}/*.frag; do
		"$qsb" --glsl "300 es,150" -o "$out/$(basename "$shader").qsb" "$shader"
	done
''
