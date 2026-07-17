{
  lib,
  pkgs,
  ...
}:

let
  platform = pkgs.stdenv.hostPlatform;

  scriptName =
    if platform.isDarwin then
      "switch-darwin.sh"
    else if platform.isLinux then
      "switch-linux.sh"
    else
      throw "mihomo-switch: unsupported platform ${platform.system}";

  source = ./.;
in
pkgs.writeShellApplication {
  name = "mihomo-switch";

  runtimeInputs = [
    pkgs.curl
    pkgs.coreutils
  ];

  text = "source ${source}/${scriptName}";

  extraShellCheckFlags = [
    "-x"
    "-P"
    (toString source)
  ];

  meta = {
    description = "Download, install, and activate a mihomo configuration";
    homepage = "https://github.com/sshawn9/nix-packages";
    mainProgram = "mihomo-switch";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };
}
