# services.screenpilot: the daemon as a user service, its settings, and what it needs.
#
#   modules = [ inputs.omniformis.nixosModules.screenpilot ];
#   services.screenpilot = { enable = true; user = "boing"; };
#
# The keys (STOP is Super + Escape) are Hyprland's, in hypr/modules/keybinds.lua like every other
# shortcut (the settings app changes them), not here. The Claude/local switch in each shell's
# Extras changes the backend at runtime; `backend` below is only where it starts.
{ config, lib, pkgs, ... }:
let
  cfg = config.services.screenpilot;
  inherit (lib) mkOption mkEnableOption mkIf types;

  lessac = pkgs.linkFarm "piper-voice-en_US-lessac-medium" [
    { name = "en_US-lessac-medium.onnx";
      path = pkgs.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx";
        sha256 = "17q1mzm6xd5i2rxx2xwqkxvfx796kmp1lvk4mwkph602k7k0kzjy";
      }; }
    { name = "en_US-lessac-medium.onnx.json";
      path = pkgs.fetchurl {
        url = "https://huggingface.co/rhasspy/piper-voices/resolve/v1.0.0/en/en_US/lessac/medium/en_US-lessac-medium.onnx.json";
        sha256 = "184hnvd8389xpdm0x2w6phss23v5pb34i0lhd4nmy1gdgd0rrqgg";
      }; }
  ];

  settings = {
    inherit (cfg) mode backend claudeModel localModel localUrl confirm blocklist stopOnUserInput stopOnClientDisconnect;
    voice = if cfg.voice == null then "" else toString cfg.voice;
  };
in
{
  options.services.screenpilot = {
    enable = mkEnableOption "screenpilot, the screen-aware assistant (ASK, ACT, speech, STOP)";
    package = mkOption {
      type = types.package;
      default = pkgs.callPackage ./package.nix { };
      description = "The screenpilot package.";
    };
    user = mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "boing";
      description = "Added to the input group, so shared mode can tell when you touch the mouse or keyboard.";
    };
    mode = mkOption {
      type = types.enum [ "sandbox" "shared" ];
      default = "sandbox";
      description = "Where ACT works: its own nested desktop (sandbox) or yours (shared).";
    };
    backend = mkOption {
      type = types.enum [ "local" "claude" ];
      default = "local";
      description = "The model it starts with; each shell's \"Screen AI: Claude\" switch changes it.";
    };
    claudeModel = mkOption { type = types.str; default = "claude-opus-5-5"; description = "The Claude model."; };
    localModel = mkOption {
      type = types.str;
      default = "qwen3-vl:8b";
      description = "The local vision model (pull it once: ollama pull <name>).";
    };
    localUrl = mkOption { type = types.str; default = "http://127.0.0.1:11434/v1"; description = "An OpenAI-compatible endpoint."; };
    voice = mkOption {
      type = types.nullOr types.path;
      default = "${lessac}/en_US-lessac-medium.onnx";
      description = "A piper voice (.onnx, with its .onnx.json next to it); null for no speech.";
    };
    confirm = mkOption {
      type = types.enum [ "always" "risky" "never" ];
      default = "risky";
      description = "When ACT asks first: every action, risky ones and each run's first, or never.";
    };
    blocklist = mkOption {
      type = types.listOf types.str;
      default = [ "(?i)keepass" "(?i)bitwarden" "(?i)1password" "(?i)seahorse" "(?i)gnome-keyring" ];
      description = "Regexes on window class and title: such a window on screen and nothing is captured.";
    };
    stopOnUserInput = mkOption { type = types.bool; default = false; description = "Shared mode: touching the mouse or keyboard is STOP, not a pause."; };
    stopOnClientDisconnect = mkOption { type = types.bool; default = false; description = "The client that started a run going away is STOP."; };
    envFile = mkOption {
      type = types.str;
      default = "%h/.config/screenpilot/env";
      description = "Read by the service (ANTHROPIC_API_KEY=...). Never in the repo.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];
    users.users = mkIf (cfg.user != null) { ${cfg.user}.extraGroups = [ "input" ]; };

    systemd.user.services.screenpilot = {
      description = "screenpilot, the screen-aware assistant";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      path = [ "/run/current-system/sw" ];  # hyprctl, qs
      environment.SCREENPILOT_CONFIG = toString (pkgs.writeText "screenpilot.json" (builtins.toJSON settings));
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/screenpilotd";
        EnvironmentFile = "-${cfg.envFile}";
        Restart = "on-failure";
        KillMode = "control-group";  # `screenpilot stop`'s last resort kills it all: sandbox, overlay, speech
      };
    };
  };
}
