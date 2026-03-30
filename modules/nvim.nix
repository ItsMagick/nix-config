{ pkgs, config, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;

    extraPackages = with pkgs; [
      git
      ripgrep
      fd
      gcc
      nodejs
      python3
      lua-language-server
      stylua
      nil
      alejandra
    ];
  };

  xdg.configFile."nvim".source = config.lib.file.mkOutOfStoreSymlink
    "./modules/nvim";
}