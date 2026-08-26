{ pkgs, ... }:
{
    programs.vesktop = {
      enable = true;
      package = pkgs.vesktop.overrideAttrs (old: {
        postFixup = (old.postFixup or "") + ''
          wrapProgram $out/bin/vesktop --add-flags "--ozone-platform-hint=auto"
        '';
      });
    };
}