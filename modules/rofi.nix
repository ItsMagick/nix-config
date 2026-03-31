{pkgs, config, lib, ...}:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    theme = lib.mkForce "${config.xdg.configHome}/rofi/matugen.rasi";
    extraConfig = {
      modi = "run,drun,window";
      icon-theme = "Papirus-Dark";
      show-icons = true;
      terminal = "kitty";
      drun-display-format = "{icon} {name}";
      location = 0;
      disable-history = false;
      hide-scrollbar = true;
      display-window = " 󰖲  Windows";
      display-drun = "   Apps";
      sidebar-mode = true;
      
      kb-element-next = "Alt+Tab,Tab";
      kb-element-prev = "Alt+Shift+Tab,Shift+Tab";
  
      kb-accept-entry = "Return,!Alt+Tab"; 
      window-format = "{w} · {c} · {t}";
    
    };
  };
}
