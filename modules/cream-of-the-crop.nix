{ inputs, ... }:

{
  xdg.configFile = {
    "projectM/presets/cream-of-the-crop" = {
      source = inputs.projectm-cream-of-the-crop;
      recursive = true;
    };
    "projectM/textures/milkdrop" = {
      source = inputs.projectm-milkdrop-texture-pack;
      recursive = true;
    };
  };
}