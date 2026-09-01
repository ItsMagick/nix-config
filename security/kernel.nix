{
  pkgs,
  ...
}:
{
  boot.kernelPackages = pkgs.linuxPackages_hardened;

  boot.kernel.sysctl = {
    "kernel.kptr_restrict" = 2;
    "kernel.dmesg_restrict" = 1;
    "kernel.yama.ptrace_scope" = 2;
    "net.ipv4.conf.all.rp_filter" = 1;
    "net.ipv4.icmp_echo_ignore_broadcasts" = 1;
    "net.ipv4.tcp_syncookies" = 1;
    "kernel.unprivileged_bpf_disabled" = 1;
    "net.core.bpf_jit_harden" = 2;
  };

  security.protectKernelImage = true;
  boot.kernelParams = [
    "slab_nomerge"
    "init_on_alloc=1"
    "init_on_free=1"
    "page_alloc.shuffle=1"
    "page_poison=1"
    "debugfs=off"
  ];
#  TODO: Look at potentially lazy loaded kernel mods like docker, wireguard etc
#  security.lockKernelModules = true;
}