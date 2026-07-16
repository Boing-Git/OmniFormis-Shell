import re

with open("WallpaperOverlay.qml", "r") as f:
    content = f.read()

new_paint = """            Connections {
                target: Vars
                function onWallpaperMaskShapeChanged() { maskCanvas.requestPaint() }
                function onWallpaperMaskScaleChanged() { maskCanvas.requestPaint() }
            }
            onPaint: {
                var ctx = getContext("2d");
                ctx.reset();
                var cx = width / 2;
                var cy = height / 2;
                var radius = width / 2;
                
                var name = Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "Star 4";
                
                var points = 4;
                var innerRatio = 0.5;
                var roundness = 0.5;
                var type = "star";
                
                if (name === "Circle") { type = "polygon"; points = 32; innerRatio = 1; roundness = 1; }
                else if (name === "Square") { type = "polygon"; points = 4; innerRatio = 1; roundness = 0; }
                else if (name === "Squircle") { type = "polygon"; points = 4; innerRatio = 1; roundness = 0.5; }
                else if (name === "Hexagon") { type = "polygon"; points = 6; innerRatio = 1; roundness = 0.1; }
                else if (name === "Octagon") { type = "polygon"; points = 8; innerRatio = 1; roundness = 0.1; }
                else if (name === "Star 4") { type = "star"; points = 4; innerRatio = 0.3; roundness = 1.0; }
                else if (name === "Star 5") { type = "star"; points = 5; innerRatio = 0.4; roundness = 1.0; }
                else if (name === "Star 6") { type = "star"; points = 6; innerRatio = 0.5; roundness = 1.0; }
                else if (name === "Star 8") { type = "star"; points = 8; innerRatio = 0.6; roundness = 1.0; }
                else if (name === "Clover 4") { type = "scallop"; points = 4; innerRatio = 0.4; roundness = 1.0; }
                else if (name === "Clover 8") { type = "scallop"; points = 8; innerRatio = 0.6; roundness = 1.0; }
                else if (name === "Scallop 8") { type = "scallop"; points = 8; innerRatio = 0.8; roundness = 1.0; }
                else if (name === "Scallop 12") { type = "scallop"; points = 12; innerRatio = 0.85; roundness = 1.0; }
                else if (name === "Burst 8") { type = "star"; points = 8; innerRatio = 0.7; roundness = 0.2; }
                else if (name === "Burst 12") { type = "star"; points = 12; innerRatio = 0.8; roundness = 0.2; }
                else if (name === "Cross") { type = "star"; points = 4; innerRatio = 0.2; roundness = 0.1; }
                else if (name === "Diamond") { type = "polygon"; points = 4; innerRatio = 1; roundness = 0.05; }
                else if (name === "Pentagon") { type = "polygon"; points = 5; innerRatio = 1; roundness = 0.1; }
                else if (name === "Heptagon") { type = "polygon"; points = 7; innerRatio = 1; roundness = 0.1; }
                else if (name === "Nonagon") { type = "polygon"; points = 9; innerRatio = 1; roundness = 0.1; }
                else if (name === "Decagon") { type = "polygon"; points = 10; innerRatio = 1; roundness = 0.1; }
                else if (name === "Dodecagon") { type = "polygon"; points = 12; innerRatio = 1; roundness = 0.1; }
                else if (name === "Star 12") { type = "star"; points = 12; innerRatio = 0.6; roundness = 1.0; }
                else if (name === "Star 16") { type = "star"; points = 16; innerRatio = 0.7; roundness = 1.0; }
                else if (name === "Clover 6") { type = "scallop"; points = 6; innerRatio = 0.5; roundness = 1.0; }
                else if (name === "Scallop 6") { type = "scallop"; points = 6; innerRatio = 0.75; roundness = 1.0; }
                else if (name === "Burst 6") { type = "star"; points = 6; innerRatio = 0.6; roundness = 0.2; }
                else if (name === "Burst 16") { type = "star"; points = 16; innerRatio = 0.85; roundness = 0.2; }
                else if (name === "Gear 8") { type = "scallop"; points = 8; innerRatio = 0.8; roundness = 0.2; }
                else if (name === "Gear 12") { type = "scallop"; points = 12; innerRatio = 0.85; roundness = 0.2; }
                else if (name === "Blob 1") { type = "blob"; points = 5; innerRatio = 0.7; roundness = 1.0; }
                else if (name === "Blob 2") { type = "blob"; points = 6; innerRatio = 0.65; roundness = 1.0; }
                else if (name === "Blob 3") { type = "blob"; points = 7; innerRatio = 0.75; roundness = 1.0; }
                else if (name === "Blob 4") { type = "blob"; points = 8; innerRatio = 0.7; roundness = 1.0; }
                else if (name === "Blob 5") { type = "blob"; points = 4; innerRatio = 0.6; roundness = 1.0; }
                
                ctx.beginPath();
                var steps = 360;
                for (var i = 0; i <= steps; i++) {
                    var angle = i * Math.PI / 180;
                    var r = radius;
                    
                    if (type === "polygon") {
                        var a = Math.PI * 2 / points;
                        var modAngle = angle % a;
                        if (modAngle < 0) modAngle += a;
                        var dist = Math.cos(a / 2) / Math.cos(a / 2 - modAngle);
                        r = radius / dist;
                        r = r * (1 - roundness) + radius * roundness;
                    } else if (type === "star" || type === "scallop" || type === "blob") {
                        if (type === "blob") {
                            var w1 = Math.sin(points * angle);
                            var w2 = Math.cos((points - 1) * angle);
                            var w = (w1 + w2) / 2;
                            w = (w + 1) / 2;
                            r = radius * (innerRatio + (1 - innerRatio) * w);
                        } else {
                            var wave = Math.cos(points * angle);
                            if (type === "scallop") {
                                wave = Math.abs(wave);
                            } else {
                                wave = (wave + 1) / 2;
                            }
                            var power = roundness * 2.0;
                            if (power === 0) power = 0.01;
                            r = radius * (innerRatio + (1 - innerRatio) * Math.pow(wave, power));
                        }
                    }
                    
                    var offset = -Math.PI / 2;
                    if (name === "Diamond") offset = 0;
                    else if (name === "Square" || name === "Squircle") offset = Math.PI / 4;
                    
                    var x = cx + r * Math.cos(angle + offset);
                    var y = cy + r * Math.sin(angle + offset);
                    if (i === 0) ctx.moveTo(x, y);
                    else ctx.lineTo(x, y);
                }
                ctx.closePath();
                ctx.fillStyle = "black";
                ctx.fill();
            }"""

content = re.sub(r'            onPaint: \{.*?\n            \}', new_paint, content, flags=re.DOTALL)

with open("WallpaperOverlay.qml", "w") as f:
    f.write(content)
