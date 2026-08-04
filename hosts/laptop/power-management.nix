{ ... } :
{
  tlp = {
    enable = true;
    settings = {
      CPU_SCALING_GOVERNOR_ON_AC = "performance";
      CPU_SCALING_GOVERNOR_ON_BAT = "powersave";

      CPU_ENERGY_PERF_POLICY_ON_BAT = "power";
      CPU_ENERGY_PERF_POLICY_ON_AC = "performance";

      CPU_MIN_PERF_ON_AC = 0;
      CPU_MAX_PERF_ON_AC = 100;
      CPU_MIN_PERF_ON_BAT = 0;
      CPU_MAX_PERF_ON_BAT = 20;

      # Optional helps save long term battery health
      START_CHARGE_THRESH_BAT0 = 40; # 40 and below it starts to charge
      STOP_CHARGE_THRESH_BAT0 = 80;  # 80 and above it stops charging
    };
  };
  services.logind = {
    settings = {
      Login = {
        LidSwitch = "suspend-then-hibernate";
        PowerKey = "hibernate";
        PowerKeyLongPress = "poweroff";
      };
    };
  };

  swapDevices = [{
    device = "/var/lib/swapfile";
    size = 32 * 1024;
  }];

  boot = {
    kernelParams = [
      "resume_offset=72464384"
      "mem_sleep_default=deep"
    ];
    resumeDevice = "/dev/disk/by-uuid/e8491619-1594-4fd3-9ae6-6e81ab1bb6c2";
  };
}