{pkgs, config, ...}:
{
  programs.rofi = {
    enable = true;
    package = pkgs.rofi;
    extraConfig = {
      modi = "run,drun,window";
      icon-theme = "Oranchelo";
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
