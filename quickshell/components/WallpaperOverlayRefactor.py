import re

with open("WallpaperOverlay.qml", "r") as f:
    content = f.read()

# Add import QtQuick.Shapes
if "import QtQuick.Shapes" not in content:
    content = content.replace("import QtQuick", "import QtQuick\nimport QtQuick.Shapes")

# Define the new Shape component
shape_code = """
    M3Shapes { id: m3 }

    Item {
        anchors.fill: parent
        
        Shape {
            id: maskCanvas
            anchors.centerIn: parent
            visible: false
            layer.enabled: true
            
            // The SVG path expects a 100x100 bounding box. We scale the Shape component
            // based on the calculated width relative to 100.
            property real calculatedSize: Math.min(parent.width, parent.height) * Vars.wallpaperMaskScale
            width: 100
            height: 100
            transform: Scale {
                origin.x: 50
                origin.y: 50
                x: maskCanvas.calculatedSize / 100
                y: maskCanvas.calculatedSize / 100
            }
            
            property string currentShapeName: Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "Circle"
            
            // Re-use Timer to track Vars changes since Vars is a JS namespace without signals
            Timer {
                interval: 100
                running: true
                repeat: true
                onTriggered: {
                    var shape = Vars.wallpaperMaskShape !== undefined ? Vars.wallpaperMaskShape : "Circle";
                    if (maskCanvas.currentShapeName !== shape) {
                        maskCanvas.currentShapeName = shape;
                    }
                }
            }
            
            ShapePath {
                fillColor: "white"
                strokeColor: "transparent"
                
                PathSvg {
                    path: m3.getPath(maskCanvas.currentShapeName)
                }
            }
        }
"""

# Replace Canvas with Shape
content = re.sub(r'    Item \{\n        anchors\.fill: parent\n        \n        // This is the mask shape\n        Canvas \{.*?\n        \}\n        \n        Item', shape_code + '\n        \n        Item', content, flags=re.DOTALL)

with open("WallpaperOverlay.qml", "w") as f:
    f.write(content)
