          .pragma library

          var _liquidGlass = false;
var _translucent = false;
var animationDuration = 240;
var blurAmount = 17;
var clockHandThickness = 16;
var clockSecondHandStyle = "Orbiting Dot";
var clockShape = "7SidedCookie";
var clockShowCenterDot = false;
var clockShowDate = true;
var clockShowTicks = false;
var componentOpacity = 0.500000;
var cornerPower = 2.5;
var currentBrightness = 1.000000;
var customEmphasizedAccelerate = [ 0.300000, 0.000000, 0.800000, 0.150000 ];
var customEmphasizedDecelerate = [ 0.050000, 0.700000, 0.100000, 1.000000 ];
var customExpressiveSpatialFast = [ 0.420000, 1.670000, 0.210000, 0.900000 ];
var customExpressiveSpatialSlow = [ 0.390000, 1.290000, 0.350000, 0.980000 ];
var customStandard = [ 0.200000, 0.000000, 0.000000, 1.000000 ];
var customStandardAccelerate = [ 0.300000, 0.000000, 1.000000, 1.000000 ];
var customStandardDecelerate = [ 0.000000, 0.000000, 0.000000, 1.000000 ];
var desktopCalenderAnchorCurve = 0;
var desktopCalenderAnchorEnabled = false;
var desktopCalenderAnchorPoint = "Center";
var desktopCalenderEnabled = false;
var desktopClockAnchorCurve = 0;
var desktopClockAnchorEnabled = true;
var desktopClockAnchorPoint = "Center";
var desktopClockEnabled = true;
var desktopMediaPlayerAnchorCurve = 1;
var desktopMediaPlayerAnchorEnabled = true;
var desktopMediaPlayerAnchorExpandFix = true;
var desktopSystemVitalsEnabled = true;
var desktopSystemVitalsAnchorEnabled = true;
var desktopSystemVitalsAnchorPoint = "Center";
var desktopSystemVitalsAnchorCurve = 4;
var desktopSystemVitalsBackgroundEnabled = true;
var desktopAudioVisualizerEnabled = true;
var desktopAudioVisualizerAnchorEnabled = true;
var desktopAudioVisualizerAnchorPoint = "Center";
var desktopAudioVisualizerAnchorCurve = 5;
var desktopAudioVisualizerBars = 23;
var desktopAudioVisualizerBackgroundEnabled = true;
var desktopAudioVisualizerShape = "12SidedCookie";
var desktopAudioVisualizerShapeMode = "All Shapes";
var desktopAudioVisualizerColorMode = "Theme";
var desktopAudioVisualizerColor = "primary";
var desktopAudioVisualizerGradientStart = "error";
var desktopAudioVisualizerGradientEnd = "primary";
var desktopAudioVisualizerLayout = "Lines";
var desktopAudioVisualizerLineArrangement = "Shape";
var desktopAudioVisualizerLineThickness = 8;
var desktopAudioVisualizerLineMirror = true;
var desktopAudioVisualizerLineDirection = "";
var desktopAudioVisualizerPositionShape = "4LeafClover";
var desktopAudioVisualizerShapeSize = 23;
var desktopAudioVisualizerSpacing = 5;
var desktopAudioVisualizerRadius = 57;
var desktopAudioVisualizerPresets = "[]";
var desktopMediaPlayerAnchorPoint = "Center";
var desktopMediaPlayerEnabled = true;
var flickDeceleration = 1500;
var fontBaselineEnabled = true;
var fontFamily = "Google Sans Flex";
var fontGrading = 0;
var fontItalic = false;
var fontRounding = 100;
var fontWeight = 500;
var gameLibraryColumns = 4;
var gameLibraryRows = 2;
var gameLibraryScale = 1;
var gameMode = false;
var m3EmphasizedAccelerate = [ 0.300000, 0.000000, 0.800000, 0.150000 ];
var m3EmphasizedDecelerate = [ 0.050000, 0.700000, 0.100000, 1.000000 ];
var m3ExpressiveSpatialFast = [ 0.420000, 1.670000, 0.210000, 0.900000 ];
var m3ExpressiveSpatialSlow = [ 0.390000, 1.290000, 0.350000, 0.980000 ];
var m3Standard = [ 0.200000, 0.000000, 0.000000, 1.000000 ];
var m3StandardAccelerate = [ 0.300000, 0.000000, 1.000000, 1.000000 ];
var m3StandardDecelerate = [ 0.000000, 0.000000, 0.000000, 1.000000 ];
var maximumFlickVelocity = 3000;
var mediaPlayerArtOffsetX = 0;
var mediaPlayerArtOffsetY = 46;
var mediaPlayerArtScale = 2;
var mediaPlayerExpandOverlaps = true;
var mediaPlayerLyricsAutoScroll = true;
var mediaPlayerLyricsExpansion = "Horizontal";
var mediaPlayerOrientation = "Vertical";
var mediaPlayerShape = "4LeafClover";
var mediaPlayerWaveThickness = 10;
var overviewGridColumns = 5;
var overviewGridRows = 2;
var overviewScale = 0.700000;
var paddingLarge = 24;
var paddingMedium = 16;
var paddingSmall = 8;
var panelOpacity = 0.600000;
var panelStyle = "Attached";
var pillPosition = "Bottom";
var clockPillMode = "Dodge Windows";
var liquidGlassPreset = "apple";
var radiusAmount = 0.500000;
var radiusSmall = 8;
var spacingLarge = 24;
var spacingMedium = 16;
var spacingSmall = 11;
var wallpaperMaskColor = "primary";
var wallpaperMaskEnabled = true;
var wallpaperMaskOffsetX = -256;
var wallpaperMaskOffsetY = 32;
var wallpaperMaskScale = 1;
var wallpaperMaskShape = "Gem";

          function getFadeCurve(isOpen) {
              return isOpen ? customEmphasizedDecelerate : customEmphasizedAccelerate;
          }

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
