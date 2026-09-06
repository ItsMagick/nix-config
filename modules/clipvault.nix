{
  pkgs,
  config,
  ...
}:
{
  xdg.configFile."clipvault/clipvault.sh" = {
    source = ../scripts/clipvault.sh;
    executable = true;
  };
}
