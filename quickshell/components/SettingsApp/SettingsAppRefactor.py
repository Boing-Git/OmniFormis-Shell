import re

with open("../SettingsApp.qml", "r") as f:
    content = f.read()

# 1. currentSection default
content = re.sub(r'property string currentSection: "hyprland".*?// "hyprland", "wifi", "bluetooth"', 'property string currentSection: "General"', content)

# 2. replace StackLayout contents
new_stack_layout = """                StackLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    currentIndex: {
                        if (root.currentSection === "bezier") return 1;
                        if (root.currentSection === "wifi") return 2;
                        if (root.currentSection === "bluetooth") return 3;
                        return 0; // "General", "Appearance", "Input" map to UnifiedSettingsPage
                    }

                    // 0: Unified Settings (Hyprland + Quickshell)
                    UnifiedSettingsPage {
                        id: unifiedPage
                        activeCategory: root.currentSection === "bezier" || root.currentSection === "wifi" || root.currentSection === "bluetooth" ? "General" : root.currentSection
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 1: Bezier Editor
                    BezierEditorPage {
                        id: bezierPage
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 2: Wi-Fi Settings
                    WifiPage {
                        id: wifiPage
                        wifiDevice: root.wifiDevice
                        panelRef: root.panel
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }

                    // 3: Bluetooth Settings
                    BluetoothPage {
                        id: bluetoothPage
                        adapter: root.adapter
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }"""

content = re.sub(r'                StackLayout \{.*\}\s*\}\s*\}\s*\}', new_stack_layout + '\n            }\n        }\n    }\n}', content, flags=re.DOTALL)

with open("../SettingsApp.qml", "w") as f:
    f.write(content)
