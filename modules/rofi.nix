{ pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
  };
  xdg.configFile."rofi/config.rasi".source = ./rofi/config.rasi;
  xdg.configFile."rofi/theme.rasi".source = ./rofi/theme.rasi;

}
