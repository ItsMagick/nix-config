{ config, ... }:

{
  home.file = {
    ".config/hypr/scripts/quickshell".source = config.lib.file.mkOutOfStoreSymlink (toString ./../scripts/quickshell);
    ".config/hypr/scripts/qs_manager.sh".source = config.lib.file.mkOutOfStoreSymlink (toString ./../scripts/qs_manager.sh);
    ".config/hypr/scripts/session_start.sh".source = config.lib.file.mkOutOfStoreSymlink (toString ./../scripts/session_start.sh);
    ".config/hypr/scripts/rofi_show.sh".source = config.lib.file.mkOutOfStoreSymlink (toString ./../scripts/rofi_show.sh);
  };
}




