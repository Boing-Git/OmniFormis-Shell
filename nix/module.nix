{ config, lib, pkgs, ... }@args:

with lib;

let
  cfg = config.programs.omniformis;
  osCfg = args.osConfig.programs.omniformis or { };

  toJS = val:
    if isBool val then (if val then "true" else "false")
    else if isInt val || isFloat val then toString val
    else if isString val then ''"${val}"''
    else if isList val then "[ " + concatStringsSep ", " (map toJS val) + " ]"
    else if isAttrs val then "{ " + concatStringsSep ", " (mapAttrsToList (k: v: "${k}: ${toJS v}") val) + " }"
    else toString val;

  toLua = val:
    if isBool val then (if val then "true" else "false")
    else if isInt val || isFloat val then toString val
    else if isString val then ''"${val}"''
    else if isList val then "{ " + concatStringsSep ", " (map toLua val) + " }"
    else if isAttrs val then "{ " + concatStringsSep ", " (mapAttrsToList (k: v: "${k} = ${toLua v}") val) + " }"
    else toString val;

  mkJSVar = name: val: "var ${name} = ${toJS val};";
  variablesJS = concatStringsSep "\n" (mapAttrsToList mkJSVar cfg.quickshell.settings);

  # keybinds.lua ships with a full combination per shortcut. Overrides are applied line by line
  # so the categories and comments the settings app reads stay intact.
  keybindsSource = builtins.readFile ../hypr/modules/keybinds.lua;
  patchBindLine = line:
    let m = builtins.match "([ \t]*)([A-Za-z0-9_]+)[ \t]*=[ \t]*\".*\"(,?)[ \t]*" line;
    in if m != null && hasAttr (elemAt m 1) cfg.hyprland.binds
       then "${elemAt m 0}${elemAt m 1} = \"${cfg.hyprland.binds.${elemAt m 1}}\"${elemAt m 2}"
       else line;
  keybindsLua = concatStringsSep "\n" (map patchBindLine (splitString "\n" keybindsSource));

  mkLuaVar = name: val: "    ${name} = ${toLua val},";
  variablesLua = concatStringsSep "\n" (mapAttrsToList mkLuaVar cfg.hyprland.settings);

in
{
  options.programs.omniformis = {
    enable = mkEnableOption "OmniFormis Shell configuration";

    dotfilesDir = mkOption {
      type = types.nullOr types.path;
      default = osCfg.dotfilesDir or null;
      description = ''
        Absolute path to a live OmniFormis-Shell checkout (e.g. ~/Dotfiles). When set,
        `~/.config/hypr` is symlinked straight to this checkout's `hypr/` folder instead of a
        frozen Nix store copy, so hand edits and the Quickshell Settings page (which both write
        through the omniformis CLI into hypr/modules/variables.lua and keybinds.lua) take effect
        on the next `hyprctl reload` instead of only after the next Home Manager switch. When
        left null, `hyprland.settings`/`hyprland.binds` are baked into an immutable copy as
        before.
      '';
    };

    quickshell = {
      enable = mkEnableOption "Quickshell configuration";
      settings = mkOption {
        type = types.attrs;
        description = "Settings for quickshell, generated into theme/variables.js";
        default = osCfg.quickshell.settings or {
        radiusAmount = 0.5;
        radiusSmall = 8;
        cornerPower = 2;
        spacingSmall = 11;
        spacingMedium = 16;
        spacingLarge = 24;
        paddingSmall = 8;
        paddingMedium = 16;
        paddingLarge = 24;
        fontFamily = "Google Sans Flex";
        fontWeight = 500;
        fontItalic = false;
        fontRounding = 100;
        fontGrading = 0;
        fontBaselineEnabled = true;
        animationDuration = 240;
        flickDeceleration = 1500;
        maximumFlickVelocity = 3000;
        _translucent = true;
        _liquidGlass = false;
        blurAmount = 17;
        panelOpacity = 0.6;
        componentOpacity = 0.5;
        currentBrightness = 1.0;
        overviewGridRows = 2;
        overviewGridColumns = 5;
        overviewScale = 0.7;
        gameLibraryRows = 2;
        gameLibraryColumns = 4;
        gameLibraryScale = 1;
        wallpaperMaskEnabled = true;
        wallpaperMaskScale = 1;
        wallpaperMaskShape = "4SidedCookie";
        wallpaperMaskColor = "primary";
        wallpaperMaskOffsetX = 6;
        wallpaperMaskOffsetY = 0;
        clockShape = "Sunny";
        clockShowTicks = false;
        clockShowCenterDot = false;
        clockShowDate = true;
        clockSecondHandStyle = "Orbiting Dot";
        clockHandThickness = 18;
        mediaPlayerShape = "Sunny";
        mediaPlayerArtScale = 2;
        mediaPlayerArtOffsetX = 0;
        mediaPlayerArtOffsetY = 59;
        mediaPlayerWaveThickness = 10;
        mediaPlayerOrientation = "Vertical";
        mediaPlayerLyricsExpansion = "Horizontal";
        mediaPlayerLyricsAutoScroll = true;
        mediaPlayerExpandOverlaps = true;
        panelStyle = "Attached";
        pillPosition = "Bottom";
        clockPillMode = "Always Visible";
        gameMode = false;
        desktopClockEnabled = true;
        desktopClockAnchorEnabled = true;
        desktopClockAnchorPoint = "Center";
        desktopClockAnchorCurve = 3;
        desktopCalenderEnabled = false;
        desktopCalenderAnchorEnabled = false;
        desktopCalenderAnchorPoint = "Center";
        desktopCalenderAnchorCurve = 0;
        desktopMediaPlayerEnabled = true;
        desktopMediaPlayerAnchorEnabled = true;
        desktopMediaPlayerAnchorPoint = "Center";
        desktopMediaPlayerAnchorCurve = 0;
        desktopMediaPlayerAnchorExpandFix = true;
        m3Standard = [0.2 0.0 0.0 1.0];
        m3StandardDecelerate = [0.0 0.0 0.0 1.0];
        m3StandardAccelerate = [0.3 0.0 1.0 1.0];
        m3EmphasizedDecelerate = [0.05 0.7 0.1 1.0];
        m3EmphasizedAccelerate = [0.3 0.0 0.8 0.15];
        m3ExpressiveSpatialFast = [0.42 1.67 0.21 0.9];
        m3ExpressiveSpatialSlow = [0.39 1.29 0.35 0.98];
        customStandard = [0.2 0.0 0.0 1.0];
        customStandardDecelerate = [0.0 0.0 0.0 1.0];
        customStandardAccelerate = [0.3 0.0 1.0 1.0];
        customEmphasizedDecelerate = [0.05 0.7 0.1 1.0];
        customEmphasizedAccelerate = [0.3 0.0 0.8 0.15];
        customExpressiveSpatialFast = [0.42 1.67 0.21 0.9];
        customExpressiveSpatialSlow = [0.39 1.29 0.35 0.98];
        };
      };
    };

    hyprland = {
      enable = mkEnableOption "Hyprland configuration";
      binds = mkOption {
        type = types.attrsOf types.str;
        default = osCfg.hyprland.binds or { };
        example = literalExpression ''
          {
            TermBind = "$MM + Return";
            WindowCloseBind = "$MM + $TM + Q";
          }
        '';
        description = ''
          Shortcuts to change, as full key combinations. Names are the entries of
          hypr/modules/keybinds.lua and a value may use variables such as $MM, $TM and $left
          (see hypr/modules/keybind_engine.lua). Shortcuts not listed keep their defaults, and an
          empty string disables one.
        '';
      };
      settings = mkOption {
        type = types.attrs;
        description = "Settings for hyprland, generated into modules/variables.lua";
        default = osCfg.hyprland.settings or {
        Browser = "zen-beta";
        Term = "wezterm";
        Editor = "antigravity";
        Files = "nautilus";
        SysInfo = "btop";
        GameMode = false;
        LowSpec = "auto";
        Layout = "Scrolling";
        kb_layout = "us,us";
        kb_variant = "colemak_dh,";
        kb_options = "grp:alt_shift_toggle,caps:escape";
        follow_mouse = 1;
        sensitivity = 0;
        touchpad_natural_scroll = false;
        gesture_fingers = 3;
        gesture_direction = "vertical";
        vimkeys = true;
        MM = "SUPER";
        SM = "ALT";
        TM = "SHIFT";
        QM = "CTRL";
        VimLeftKey = "m";
        VimDownKey = "n";
        VimUpKey = "e";
        VimRightKey = "i";
        gaps_in = 5;
        gaps_out = 15;
        border_size = 2;
        rounding = 35;
        rounding_power = 13;
        active_opacity = 1.0;
        inactive_opacity = 0.95;
        windowOpacity = "0.9";
        enableSingleWindowGaps = false;
        singleWindowGapsOut = 30;
        enableSpecialWorkspaceGaps = false;
        shadow_enabled = true;
        shadow_range = 30;
        shadow_render_power = 2;
        blur_enabled = true;
        blur_size = 4;
        blur_passes = 4;
        blur_vibrancy = 0.1696;
        liquidGlass = false;
        liquidGlassPreset = "apple";
        groupBar = true;
        resize_on_border = true;
        allow_tearing = false;
        force_default_wallpaper = 0;
        disable_hyprland_logo = true;
        allow_session_lock_restore = true;
        vrr = 1;
        xwayland_force_zero_scaling = true;
        xwayland_use_nearest_neighbor = true;
        cursor_theme = "GoogleDot-Black";
        env_xcursor_size = 24;
        env_hyprcursor_size = 24;
        env_qt_scale_factor = 1;
        AnimateStyle = "slipstream";
        CustomStandard = "0.98, 0.09, 0.42, 0.50";
        CustomStandardDecelerate = "0.00, 0.00, 0.00, 1.00";
        CustomStandardAccelerate = "1.00, 0.13, 0.63, 0.42";
        CustomEmphasizedDecelerate = "0.05, 0.7, 0.1, 1.0";
        CustomEmphasizedAccelerate = "0.3, 0.0, 0.8, 0.15";
        CustomExpressiveSpatialFast = "0.42, 1.67, 0.21, 0.9";
        CustomExpressiveSpatialSlow = "0.39, 1.29, 0.35, 0.98";
        };
      };
    };

    wezterm.enable = mkEnableOption "Wezterm configuration";
    fish.enable = mkEnableOption "Fish configuration";
    btop.enable = mkEnableOption "Btop configuration";
    cava.enable = mkEnableOption "Cava configuration";
    nvim.enable = mkEnableOption "Neovim configuration";
    spicetify.enable = mkEnableOption "Spicetify configuration";
    nvtop.enable = mkEnableOption "Nvtop configuration";
    fastfetch.enable = mkEnableOption "Fastfetch configuration";
    qt5ct.enable = mkEnableOption "Qt5ct configuration";
    qt6ct.enable = mkEnableOption "Qt6ct configuration";
    nwg-look.enable = mkEnableOption "Nwg-look configuration";
    starship.enable = mkEnableOption "Starship configuration";
    color-schemes.enable = mkEnableOption "Color-schemes configuration";
    matugen.enable = mkEnableOption "Matugen configuration";
    qtengine.enable = mkEnableOption "Qtengine configuration";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      imagemagick
      bc
      python3
      # Laptop backlight for the brightness keys (hypr/modules/binds.lua)
      brightnessctl
    ];
    xdg.configFile = mkMerge [
      (mkIf cfg.quickshell.enable (
        if cfg.dotfilesDir != null then
          # Live checkout: Settings page writes and the shell's own reload script act on these
          # files directly, instead of on a copy frozen at the last Home Manager switch (and
          # which Home Manager would refuse to activate over anyway, since this path is
          # typically already a manually-created live-editing symlink from before this option
          # existed — activation aborts the whole generation rather than clobber a foreign file).
          { "quickshell".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesDir}/quickshell"; }
        else {
        "quickshell".source = pkgs.runCommand "quickshell-config" {} ''
          mkdir -p $out
          cp -r ${../quickshell}/* $out/
          chmod -R +w $out
          cat > $out/theme/variables.js <<'EOF'
          .pragma library

          ${variablesJS}

          function getTopLeftRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (style === "Attached" && (pos === "Top" || pos === "Left")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getTopRightRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (style === "Attached" && (pos === "Top" || pos === "Right")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getBottomLeftRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (style === "Attached" && (pos === "Bottom" || pos === "Left")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getBottomRightRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (style === "Attached" && (pos === "Bottom" || pos === "Right")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function fuzzyMatch(pattern, str) {
              if (!pattern) return true;
              if (!str) return false;
              pattern = pattern.toLowerCase();
              str = str.toLowerCase();
              var words = pattern.split(/\s+/);
              for (var w = 0; w < words.length; w++) {
                  var word = words[w];
                  if (!word) continue;
                  var patternIdx = 0;
                  var found = false;
                  for (var i = 0; i < str.length; i++) {
                      if (str[i] === word[patternIdx]) {
                          patternIdx++;
                          if (patternIdx === word.length) {
                              found = true;
                              break;
                          }
                      }
                  }
                  if (!found) return false;
              }
              return true;
          }

          function fuzzyMatchScore(pattern, str) {
              if (!pattern) return 1;
              if (!str) return 0;
              var lowerPattern = pattern.toLowerCase();
              var lowerStr = str.toLowerCase();
              if (lowerStr === lowerPattern) return 1000;
              if (lowerStr.startsWith(lowerPattern)) return 500;
              if (lowerStr.includes(lowerPattern)) return 300;
              var words = lowerPattern.split(/\s+/);
              var totalScore = 0;
              for (var w = 0; w < words.length; w++) {
                  var word = words[w];
                  if (!word) continue;
                  var patternIdx = 0;
                  var score = 0;
                  var consecutive = 0;
                  var found = false;
                  for (var i = 0; i < lowerStr.length; i++) {
                      if (lowerStr[i] === word[patternIdx]) {
                          score += 10 + (consecutive * 5);
                          if (i === 0) score += 50;
                          else if (lowerStr[i-1] === ' ' || lowerStr[i-1] === '-') score += 30;
                          else if (str[i] >= 'A' && str[i] <= 'Z') score += 20;
                          consecutive++;
                          patternIdx++;
                          if (patternIdx === word.length) {
                              if (i === lowerStr.length - 1 || lowerStr[i+1] === ' ') score += 20;
                              found = true;
                              totalScore += score;
                              break;
                          }
                      } else {
                          consecutive = 0;
                      }
                  }
                  if (!found) return 0;
              }
              return totalScore - lowerStr.length;
          }

          function isTranslucent() {
              return _translucent && !gameMode;
          }

          function tColor(baseColor, alpha) {
              if (!isTranslucent()) return baseColor;
              return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, alpha);
          }

          function tColorActive(isActive, baseColor, alpha) {
              if (!isActive) return "transparent";
              return tColor(baseColor, alpha);
          }

          function tColorSelected(baseColor, alpha) {
              if (!isTranslucent()) return baseColor;
              var targetAlpha = (alpha !== undefined && alpha !== null) ? alpha : 0.90;
              return Qt.rgba(baseColor.r, baseColor.g, baseColor.b, targetAlpha);
          }

          var notificationHistory = [];
          var historyUpdated = 0;
          // Set by theme/Vars.qml. An entry's own dismiss() removes it in here, so this is how
          // the shell hears about it.
          var historyChanged = null;

          function pushNotification(modelData) {
              if (!modelData) return;
              var uniqueId = modelData.seqId !== undefined ? modelData.seqId : (modelData.id !== undefined ? modelData.id : Math.random());
              for (var i = 0; i < notificationHistory.length; i++) {
                  if (notificationHistory[i].seqId === uniqueId) return;
              }
              var actionsArray = [];
              if (modelData.actions) {
                  for (var j = 0; j < modelData.actions.length; j++) {
                      actionsArray.push({ identifier: modelData.actions[j].identifier, text: modelData.actions[j].text });
                  }
              }
              var n = {
                  seqId: uniqueId,
                  appName: modelData.appName,
                  appIcon: modelData.appIcon,
                  summary: modelData.summary,
                  body: modelData.body,
                  image: modelData.image,
                  urgency: modelData.urgency,
                  actions: actionsArray,
                  expireTimeout: modelData.expireTimeout,
                  defaultTimeout: modelData.defaultTimeout,
                  invokeAction: function(id) { try { modelData.invokeAction(id); } catch(e) {} },
                  dismiss: function() { try { modelData.dismiss(); } catch(e) {} removeNotification(this.seqId); }
              };
              notificationHistory.unshift(n);
              historyUpdated++;
          }

          function removeNotification(seqId) {
              var initialLen = notificationHistory.length;
              notificationHistory = notificationHistory.filter(function(n) { return n.seqId !== seqId; });
              if (notificationHistory.length !== initialLen) {
                  historyUpdated++;
                  if (historyChanged) historyChanged();
              }
          }

          function clearNotifications() {
              for (var i = 0; i < notificationHistory.length; i++) {
                  var n = notificationHistory[i];
                  if (n && typeof n.dismiss === 'function' && !n.closed) n.dismiss();
              }
              notificationHistory = [];
              historyUpdated++;
          }
EOF
        '';
      }
      ))
      (mkIf cfg.hyprland.enable (
        if cfg.dotfilesDir != null then
          # Live checkout: hyprctl reload (and the Settings page's omniformis writes) act on
          # these files directly, instead of on a copy frozen at the last Home Manager switch.
          { "hypr".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesDir}/hypr"; }
        else {
          "hypr".source = pkgs.runCommand "hyprland-config" {} ''
            mkdir -p $out
            cp -r ${../hypr}/* $out/
            chmod -R +w $out
            cp ${pkgs.writeText "keybinds.lua" keybindsLua} $out/modules/keybinds.lua
            cat > $out/modules/variables.lua <<'EOF'
            ----------------------------------------------------------------------------------------
            --- These variables will be used in various locations in the hypr config so set them ---
            ----------------------------------------------------------------------------------------

            local vars = {

            ${variablesLua}

            }

            return vars
EOF
          '';
        }
      ))
      (mkIf cfg.wezterm.enable { "wezterm".source = ../wezterm; })
      (mkIf cfg.fish.enable { "fish".source = ../fish; })
      (mkIf cfg.btop.enable { "btop".source = ../btop; })
      (mkIf cfg.cava.enable { "cava".source = ../cava; })
      (mkIf cfg.nvim.enable { "nvim".source = ../nvim; })
      (mkIf cfg.spicetify.enable { "spicetify".source = ../spicetify; })
      (mkIf cfg.nvtop.enable { "nvtop".source = ../nvtop; })
      (mkIf cfg.fastfetch.enable { "fastfetch".source = ../fastfetch; })
      (mkIf cfg.qt5ct.enable { "qt5ct".source = ../qt5ct; })
      (mkIf cfg.qt6ct.enable { "qt6ct".source = ../qt6ct; })
      (mkIf cfg.nwg-look.enable { "nwg-look".source = ../nwg-look; })
      (mkIf cfg.starship.enable { "starship.toml".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.config/color-schemes/current/starship.toml"; })
      # color-schemes is NOT Nix-managed — it must be writable for matugen to generate theme files.
      # Static themes (gruvbox, etc.) are deployed by the install script instead.
      # Live checkout: template edits in the repo take effect on the next matugen run,
      # instead of matugen rendering a copy frozen at the last Home Manager switch.
      (mkIf cfg.matugen.enable (
        if cfg.dotfilesDir != null then
          { "matugen".source = config.lib.file.mkOutOfStoreSymlink "${cfg.dotfilesDir}/matugen"; }
        else
          { "matugen".source = ../matugen; }
      ))
      (mkIf cfg.qtengine.enable { "qtengine".source = ../qtengine; })
    ];
  };
}
