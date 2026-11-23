          .pragma library

          var _liquidGlass = false;
var _translucent = true;
var animationDuration = 240;
var assistant = true;
var mascots = true;
var reduceMotion = false;
var reduceTransparency = false;
var blurAmount = 17;
var clockDateBadgeColor = "primary";
var clockDateShape = "4SidedCookie";
var clockHandThickness = 14;
var clockSecondHandStyle = "Orbiting Dot";
var clockShape = "7SidedCookie";
var clockShowCenterDot = false;
var clockShowDate = true;
var clockShowTicks = false;
var componentOpacity = 0.5;
var cornerPower = 4.6;
var currentBrightness = 1;
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
var desktopClockAnchorCurve = 5;
var desktopClockAnchorEnabled = true;
var desktopClockAnchorPoint = "Center";
var desktopClockEnabled = true;
var desktopMediaPlayerAnchorCurve = 4;
var desktopMediaPlayerAnchorEnabled = true;
var desktopMediaPlayerAnchorExpandFix = true;
var desktopSystemVitalsEnabled = true;
var desktopSystemVitalsAnchorEnabled = true;
var desktopSystemVitalsAnchorPoint = "Center";
var desktopSystemVitalsAnchorCurve = 2;
var desktopSystemVitalsBackgroundEnabled = true;
var desktopAudioVisualizerEnabled = true;
var desktopAudioVisualizerAnchorEnabled = true;
var desktopAudioVisualizerAnchorPoint = "Center";
var desktopAudioVisualizerAnchorCurve = 1;
var desktopAudioVisualizerBars = 17;
var desktopAudioVisualizerBackgroundEnabled = true;
var desktopAudioVisualizerShape = "Circle";
var desktopAudioVisualizerShapeMode = "All Shapes";
var desktopAudioVisualizerColorMode = "Theme";
var desktopAudioVisualizerColor = "primary";
var desktopAudioVisualizerGradientStart = "error";
var desktopAudioVisualizerGradientEnd = "primary";
var desktopAudioVisualizerLayout = "Circular";
var desktopAudioVisualizerLineArrangement = "Shape";
var desktopAudioVisualizerLineThickness = 8;
var desktopAudioVisualizerLineMirror = true;
var desktopAudioVisualizerLineDirection = "";
var desktopAudioVisualizerPositionShape = "Clamshell";
var desktopAudioVisualizerShapeSize = 23;
var desktopAudioVisualizerSpacing = 5;
var desktopAudioVisualizerRadius = 58;
var desktopAudioVisualizerPresets = "[]";
var desktopMediaPlayerAnchorPoint = "Center";
var desktopMediaPlayerEnabled = true;
var flickDeceleration = 1500;
var fontBaselineEnabled = true;
var fontFamily = "Google Sans Flex";
var fontGrading = -11;
var fontItalic = false;
var fontRounding = 100;
var fontWeight = 600;
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
var mediaPlayerArtOffsetY = 51;
var mediaPlayerArtScale = 2;
var mediaPlayerExpandOverlaps = false;
var mediaPlayerLyricsAutoScroll = true;
var mediaPlayerLyricsExpansion = "Vertical";
var mediaPlayerOrientation = "Vertical";
var mediaPlayerShape = "6SidedCookie";
var mediaPlayerWaveThickness = 10;
var overviewGridColumns = 5;
var overviewGridRows = 2;
var overviewScale = 0.7;
var paddingLarge = 24;
var paddingMedium = 16;
var paddingSmall = 8;
var panelOpacity = 0.600000;
var panelStyle = "Attached";
var pillPosition = "Right";
var clockPillMode = "Dodge Windows";
var liquidGlassPreset = "apple";
var radiusAmount = 0.5;
var radiusSmall = 8;
var spacingLarge = 24;
var spacingMedium = 16;
var spacingSmall = 11;
var wallpaperMaskColor = "primary";
var wallpaperMaskEnabled = true;
var wallpaperMaskOffsetX = 0;
var wallpaperMaskOffsetY = 0;
var wallpaperMaskScale = 1.1;
var wallpaperMaskShape = "Clamshell";

          function getFadeCurve(isOpen) {
              return isOpen ? customEmphasizedDecelerate : customEmphasizedAccelerate;
          }

          // "Flat" positions flush against the screen edge exactly the same as "Attached" does
          // (see defaultEdgeMargin in TopPills.qml, activeMargin in Overview.qml/GameLibrary.qml,
          // and the margin in ClockStrut.qml — all four already treat the two styles identically
          // for zero margin) but this file only zeroed the edge-touching corner for "Attached",
          // not "Flat" — so a "Flat" pill sat flush against the screen edge while still rendering
          // a full rounded corner there, which then got clipped by the actual screen boundary
          // instead of rendering flush, leaving a visible gap/notch where the curve was cut off.
          function _isFlush(style) { return style === "Attached" || style === "Flat"; }

          function getTopLeftRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (_isFlush(style) && (pos === "Top" || pos === "Left")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getTopRightRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (_isFlush(style) && (pos === "Top" || pos === "Right")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getBottomLeftRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (_isFlush(style) && (pos === "Bottom" || pos === "Left")) return 0;
              if (style === "Framed") return 0;
              return rad;
          }

          function getBottomRightRadius(style, pos, isGame, defRad) {
              var rad = (defRad !== undefined && defRad !== null) ? defRad : 24;
              if (isGame || !style || !pos) return rad;
              if (_isFlush(style) && (pos === "Bottom" || pos === "Right")) return 0;
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
