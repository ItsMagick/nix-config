{pkgs, ...}:

let
  patchedAgnoster = pkgs.runCommand "agnoster-patched.zsh-theme" { } ''
    cp ${pkgs.oh-my-zsh}/share/oh-my-zsh/themes/agnoster.zsh-theme temp.zsh-theme
    ${pkgs.patch}/bin/patch temp.zsh-theme ${./modules/agnoster_venv_pathshortening.patch} -o $out
  '';
in
{
  programs.zsh = {
    enable = true;

    enableCompletion = true;

    autosuggestion.enable = true;

    history = {
      size = 1000;
      save = 2000;
      ignoreDups = true;
      ignoreSpace = true;
      expireDuplicatesFirst = true;
    };

    shellAliases = {
      ll = "ls -l";
      la = "ls -A";
      l  = "ls -CF";
      sl = "ls";
      update = "sudo nixos-rebuild switch --flake ~/Documents/nix-config/#TPS";
    };

    oh-my-zsh = {
      enable = true;
      theme = "agnoster";
      plugins = ["git"];
    };

    initExtra = ''
      source ${patchedAgnoster}
    '';
  };
}
