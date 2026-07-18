import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "../.."
import "../../Variables/variables.js" as Vars

Item {
    id: aboutPage
    
    property string osName: "Unknown OS"
    property string hostModel: "Unknown Hardware"
    property string cpuName: "Unknown CPU"
    property string gpuName: "Unknown GPU"
    property string memName: "Unknown RAM"

    Process {
        id: fastfetchProc
        command: ["fastfetch"] // Run without json to parse custom config output
        running: true
        stdout: StdioCollector {
            onStreamFinished: {
                // Strip ANSI escape codes
                let rawText = this.text;
                let cleanText = rawText.replace(/\x1B\[[0-9;]*[a-zA-Z]/g, '');
                
                let osMatch = cleanText.match(/OS:\s*([^\n\r]+)/);
                if (osMatch) aboutPage.osName = osMatch[1].trim();
                
                let cpuMatch = cleanText.match(/CPU:\s*([^\n\r]+)/);
                if (cpuMatch) aboutPage.cpuName = cpuMatch[1].trim();
                
                let gpuMatch = cleanText.match(/GPU:\s*([^\n\r]+)/);
                if (gpuMatch) aboutPage.gpuName = gpuMatch[1].trim();
                
                let memMatch = cleanText.match(/Memory:\s*([^\n\r]+)/);
                if (memMatch) aboutPage.memName = memMatch[1].trim();
                
                let hostMatch = cleanText.match(/Host:\s*([^\n\r]+)/);
                if (hostMatch) {
                    aboutPage.hostModel = hostMatch[1].trim();
                } else {
                    aboutPage.hostModel = "PC";
                }
            }
        }
    }
    
    Flickable {
        anchors.fill: parent
        contentHeight: aboutLayout.implicitHeight
        clip: true
        interactive: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: aboutLayout
            width: parent.width
            spacing: Vars.spacingLarge
            
            Item { Layout.preferredHeight: Vars.spacingLarge }

            // Logo & Header
            ColumnLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: Vars.spacingSmall
                
                Rectangle {
                    Layout.alignment: Qt.AlignHCenter
                    width: 96; height: 96
                    radius: 48
                    color: Theme.primary_container
                    clip: true
                    
                    // To add an image to this logo, uncomment the Image component below and set the source.
                    // Image {
                    //     anchors.fill: parent
                    //     source: "file:///home/boing/Pictures/logo.png"
                    //     fillMode: Image.PreserveAspectCrop
                    // }
                    
                    Text {
                        anchors.centerIn: parent
                        font.family: "Material Symbols Outlined"
                        font.pixelSize: 48
                        color: Theme.on_primary_container
                        text: "code"
                        // Add `visible: false` here if you uncomment the Image above.
                    }
                }
                
                Text {
                    text: "OmniFormis Shell"
                    font.family: Vars.fontFamily
                    font.pixelSize: 28
                    font.weight: Font.Bold
                    color: Theme.on_surface
                    Layout.alignment: Qt.AlignHCenter
                }
                
                Text {
                    text: "Version 1.0"
                    font.family: Vars.fontFamily
                    font.pixelSize: 16
                    color: Theme.on_surface_variant
                    Layout.alignment: Qt.AlignHCenter
                }
            }
            
            Item { Layout.preferredHeight: Vars.spacingMedium }

            // Info Cards
            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: Vars.spacingLarge
                Layout.rightMargin: Vars.spacingLarge
                spacing: 2
                
                // System Info Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 16
                    color: Theme.surface_container
                    
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                    }
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.bottom: parent.bottom; anchors.right: parent.right
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        
                        Text { text: "grid_view"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "System Components"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: Font.Medium; color: Theme.on_surface }
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "Powered by Quickshell & Hyprland"; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9 }
                        }
                    }
                }

                // PC Hardware Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: hardwareLayout.implicitHeight + 32
                    radius: 16
                    color: Theme.surface_container
                    
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.top: parent.top; anchors.left: parent.left
                    }
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.top: parent.top; anchors.right: parent.right
                    }
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.bottom: parent.bottom; anchors.left: parent.left
                    }
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.bottom: parent.bottom; anchors.right: parent.right
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        anchors.topMargin: 16
                        anchors.bottomMargin: 16
                        spacing: 16
                        
                        Text { Layout.alignment: Qt.AlignTop; text: "memory"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                        ColumnLayout {
                            id: hardwareLayout
                            Layout.fillWidth: true
                            spacing: 4
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "Hardware & OS"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: Font.Medium; color: Theme.on_surface }
                            
                            Item { Layout.preferredHeight: 2 } // spacer
                            
                            // OS Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "OS:"; font.family: Vars.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.on_surface_variant; opacity: 0.8 }
                                Text { Layout.fillWidth: true; text: aboutPage.osName; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9; elide: Text.ElideRight }
                            }
                            
                            // Host Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "PC:"; font.family: Vars.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.on_surface_variant; opacity: 0.8 }
                                Text { Layout.fillWidth: true; text: aboutPage.hostModel; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9; elide: Text.ElideRight }
                            }
                            
                            // CPU Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "CPU:"; font.family: Vars.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.on_surface_variant; opacity: 0.8 }
                                Text { Layout.fillWidth: true; text: aboutPage.cpuName; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9; elide: Text.ElideRight }
                            }
                            
                            // GPU Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "GPU:"; font.family: Vars.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.on_surface_variant; opacity: 0.8 }
                                Text { Layout.fillWidth: true; text: aboutPage.gpuName; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9; elide: Text.ElideRight }
                            }
                            
                            // RAM Row
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8
                                Text { text: "RAM:"; font.family: Vars.fontFamily; font.pixelSize: 12; font.weight: Font.Medium; color: Theme.on_surface_variant; opacity: 0.8 }
                                Text { Layout.fillWidth: true; text: aboutPage.memName; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9; elide: Text.ElideRight }
                            }
                        }
                    }
                }

                // Dev Card
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 72
                    radius: 16
                    color: Theme.surface_container
                    
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.top: parent.top; anchors.left: parent.left
                    }
                    Rectangle {
                        width: parent.radius; height: parent.radius; color: parent.color
                        anchors.top: parent.top; anchors.right: parent.right
                    }
                    
                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 20
                        anchors.rightMargin: 20
                        spacing: 16
                        
                        Text { text: "engineering"; font.family: "Material Symbols Outlined"; font.pixelSize: 24; color: Theme.on_surface_variant }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "Developer"; font.family: Vars.fontFamily; font.pixelSize: 16; font.weight: Font.Medium; color: Theme.on_surface }
                            Text { Layout.fillWidth: true; horizontalAlignment: Text.AlignLeft; text: "Created by boing"; font.family: Vars.fontFamily; font.pixelSize: 12; color: Theme.on_surface_variant; opacity: 0.9 }
                        }
                    }
                }
            }
            
            Item { Layout.fillHeight: true }
        }
    }
}
