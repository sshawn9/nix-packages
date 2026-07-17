{
  lib,
  pkgs,
  ...
}:

pkgs.writeShellApplication {
  name = "mihomo-get-zashboard";

  runtimeInputs = with pkgs; [
    curl
    unzip
    coreutils
  ];

  meta = {
    description = "Download and install the latest Zashboard web UI for mihomo";
    homepage = "https://github.com/sshawn9/nix-packages";
    mainProgram = "mihomo-get-zashboard";
    platforms = lib.platforms.linux ++ lib.platforms.darwin;
  };

  text = builtins.readFile ./get-zashboard.sh;
}
