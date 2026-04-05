{pkgs, ...}:
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
  };
}
