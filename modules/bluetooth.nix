{ ... }:
{
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;
    settings = {
      General = {
        Enable = "Source, Sink, Media, Socket";
        Experimental = true;
        AutoConnect = true;
        FastConnectable = true;
      };
    };
  };
  services.blueman.enable = true;
}