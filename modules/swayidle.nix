{ pkgs, ... }:

{
  services.swayidle = {
    enable = true;
    
    events = {
      before-sleep = "lock-screen";
      lock = "lock-screen";
    };

    timeouts = [
      { timeout = 300; command = "lock-screen"; }
      { 
        timeout = 600; 
        command = "${pkgs.hyprland}/bin/hyprctl dispatch dpms off";
        resumeCommand = "${pkgs.hyprland}/bin/hyprctl dispatch dpms on";
      }
    ];
  };
}
