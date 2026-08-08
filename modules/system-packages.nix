{ pkgs, ...}:
{
  environment.systemPackages = with pkgs; [
    wget
    git
    firefox
    rofi
    cryptsetup
    bluez
    hyprpaper
  ];
}