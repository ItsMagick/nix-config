{ config, lib, pkgs, ... }:

let
  # Set to true for the FIRST login only (opens a GUI window for the Microsoft
  # OAuth2 flow). After the token is stored, set back to false and rebuild.
  firstLogin = true;

  javaProps = pkgs.formats.javaProperties { };

  settings = {
    # --- Exchange / O365 connection (Hof University = Microsoft 365) ---
    "davmail.url" = "https://outlook.office365.com/EWS/Exchange.asmx";
    # Options: O365Modern, O365Interactive, O365Manual, EWS, Auto
    "davmail.mode" = "O365Interactive";
    # "davmail.defaultDomain" = "hof-university.de";
    # Only needed if your tenant blocks DavMail's default app registration:
    # "davmail.oauth.tenantId" = "your-tenant-id";
    # "davmail.oauth.clientId" = "your-client-id";
    # "davmail.oauth.redirectUri" = "https://login.microsoftonline.com/common/oauth2/nativeclient";

    # --- Token persistence (so you don't re-login after every restart) ---
    "davmail.oauth.persistToken" = true;
    "davmail.oauth.tokenFilePath" = "${config.xdg.stateHome}/davmail/tokens";

    # --- Local listening ports (point Thunderbird here) ---
    "davmail.imapPort" = 1143;
    "davmail.smtpPort" = 1025;
    "davmail.caldavPort" = 1080;
    "davmail.ldapPort" = 1389;

    # --- Security: loopback only ---
    "davmail.bindAddress" = "127.0.0.1";
    "davmail.allowRemote" = false;
    "davmail.disableUpdateCheck" = true;

    # --- Behaviour ---
    "davmail.server" = !firstLogin; # headless unless doing first login
    "davmail.enableKeepAlive" = true;
    "davmail.imapAutoExpunge" = true;
    "davmail.smtpSaveInSent" = true; # so disable "copy to Sent" in Thunderbird
    "davmail.keepDelay" = 30;
    "davmail.sentKeepDelay" = 90;

    # --- Logging (goes to the systemd journal) ---
    "log4j.rootLogger" = "WARN";
    "log4j.logger.davmail" = "WARN";
    "log4j.logger.httpclient.wire" = "WARN";
    "log4j.logger.org.apache.commons.httpclient" = "WARN";
  };

  # The javaProperties generator in current nixpkgs only accepts strings,
  # so convert bools/ints before generating.
  stringify = v: if builtins.isBool v then lib.boolToString v else toString v;

  configFile = javaProps.generate "davmail.properties"
    (lib.mapAttrs (_: stringify) settings);
  userConfig = "${config.xdg.configHome}/davmail/davmail.properties";
in
{
  home.packages = [ pkgs.davmail ];

  # DavMail needs a WRITABLE properties file (it saves OAuth tokens there).
  # On each switch we regenerate it from `settings` above, but keep any
  # stored refresh tokens from the existing file.
  home.activation.davmailConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    cfg="${userConfig}"
    run mkdir -p "$(dirname "$cfg")" "${config.xdg.stateHome}/davmail"
    tmp="$(mktemp)"
    cat ${configFile} > "$tmp"
    if [ -f "$cfg" ]; then
      grep -E '^davmail\.oauth\..*refreshToken' "$cfg" >> "$tmp" || true
    fi
    run install -m 600 "$tmp" "$cfg"
    rm -f "$tmp"
  '';

  systemd.user.services.davmail = {
    Unit = {
      Description = "DavMail Exchange/O365 gateway";
      After = [ "network-online.target" ];
      Wants = [ "network-online.target" ];
    };

    Service = {
      Type = "simple";
      ExecStart = "${pkgs.davmail}/bin/davmail ${userConfig}";
      Restart = "on-failure";
      RestartSec = 10;
      NoNewPrivileges = true;
      PrivateTmp = true;
    };

    # With firstLogin = true the service needs a display, so don't autostart;
    # run `davmail` manually from a graphical session instead.
    Install.WantedBy = lib.optional (!firstLogin) "default.target";
  };
}

# Setup:
#   1. imports = [ ./davmail.nix ];
#   2. Set firstLogin = true, run `home-manager switch`, then run
#      `systemctl --user stop davmail; davmail` from a graphical session and
#      log in with <you>@hof-university.de. Quit it when done.
#   3. Set firstLogin = false, `home-manager switch` again.
#
# Thunderbird (both accounts' servers):
#   IMAP  localhost:1143, security None, auth "Normal password"
#   SMTP  localhost:1025, security None, auth "Normal password"
#   Username: full address, e.g. <you>@hof-university.de
#   Disable "Place a copy of sent messages" (DavMail already saves to Sent).
