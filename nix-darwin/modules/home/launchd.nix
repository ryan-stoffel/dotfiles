{ config, pkgs, ... }:
let
  hermes = "${config.home.homeDirectory}/.hermes";
  gateway = pkgs.writeShellScript "hermes-gateway" ''
    # A fresh Mac can rebuild before Hermes provisions its private environment.
    python="${hermes}/hermes-agent/venv/bin/python"
    [ -x "$python" ] || exit 0
    mkdir -p "${hermes}/logs"
    exec "$python" -m hermes_cli.stderr_timestamp \
      --error-log "${hermes}/logs/gateway.error.log" -- \
      "$python" -m hermes_cli.main gateway run --external-supervisor
  '';
in
{
  launchd.agents.hermes = {
    enable = true;
    config = {
      Label = "ai.hermes.gateway";
      ProgramArguments = [ "${gateway}" ];
      EnvironmentVariables = {
        PATH = "${hermes}/hermes-agent/venv/bin:${hermes}/hermes-agent/node_modules/.bin:${hermes}/node/bin:${config.home.homeDirectory}/.local/bin:/etc/profiles/per-user/${config.home.username}/bin:/run/current-system/sw/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin";
        VIRTUAL_ENV = "${hermes}/hermes-agent/venv";
        HERMES_HOME = hermes;
        HERMES_SUPERVISED_CHILD = "1";
      };
      RunAtLoad = true;
      KeepAlive.SuccessfulExit = false;
      ThrottleInterval = 30;
      ExitTimeOut = 25;
      SoftResourceLimits.NumberOfFiles = 4096;
      StandardOutPath = "${config.home.homeDirectory}/Library/Logs/hermes-gateway.log";
      StandardErrorPath = "${config.home.homeDirectory}/Library/Logs/hermes-gateway.error.log";
    };
  };
}
