{
  pkgs,
  ...
}:
{
  boot.kernelParams = [
   # Don't merge slabs
   "slab_nomerge"
   # Overwrite free'd pages
   "page_poison=1"
   # Enable page allocator randomization
   "page_alloc.shuffle=1"
   # Disable debugfs
   "debugfs=off"
  ];
#  TODO: Look at potentially lazy loaded kernel mods like docker, wireguard etc
#  security.lockKernelModules = true;
}