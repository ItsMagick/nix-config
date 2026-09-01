{ ... }:
{
  imports = [
    ./apparmor.nix
    ./kernel.nix
    ./modules.nix
    ./systemctl.nix
    ./systemd.nix
  ];
}