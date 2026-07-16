import QtQuick
import "."
import Quickshell
import Quickshell.Wayland
import Quickshell.Io
import Quickshell.Hyprland

ShellRoot {
    id: root

    property bool _initApp: {
        Qt.application.name = "quickshell";
        Qt.application.organization = "boing";
        Qt.application.domain = "boing.quickshell";
        return true;
    }

    property bool launcherVisible: false
    property bool screenshotVisible: false
    property bool powerMenuVisible: false
    property bool overviewVisible: false

    onOverviewVisibleChanged: {
        if (overviewVisible) {
            topPills.closeAll();
            screenshotVisible = false;
        }
    }

    onScreenshotVisibleChanged: {
        if (screenshotVisible) {
            topPills.closeAll();
            overviewVisible = false;
        }
    }

    // Global shortcuts route to TopPills
    GlobalShortcut {
        name: "launcher"
        description: "Toggle Launcher"
        onPressed: topPills.toggleLauncher()
    }

    GlobalShortcut {
        name: "control_center"
        description: "Toggle Control Center"
        onPressed: topPills.toggleControlCenter()
    }

    GlobalShortcut {
        name: "screenshot"
        description: "Toggle Screenshot"
        onPressed: root.screenshotVisible = !root.screenshotVisible
    }

    GlobalShortcut {
        name: "power_menu"
        description: "Toggle Power Menu"
        onPressed: topPills.togglePowerMenu()
    }

    GlobalShortcut {
        name: "wallpaper"
        description: "Toggle Wallpaper Switcher"
        onPressed: topPills.toggleWallpaper()
    }

    GlobalShortcut {
        name: "color_scheme"
        description: "Toggle Color Scheme Switcher"
        onPressed: topPills.toggleColorScheme()
    }

    GlobalShortcut {
        name: "overview"
        description: "Toggle Overview"
        onPressed: root.overviewVisible = !root.overviewVisible
    }

    GlobalShortcut {
        name: "emoji_picker"
        description: "Toggle Emoji Picker"
        onPressed: topPills.toggleEmojiPicker()
    }

    GlobalShortcut {
        name: "clipboard"
        description: "Toggle Clipboard"
        onPressed: topPills.toggleClipboard()
    }

    ScreenShot {
        // Binding the internal visibility state to your root state variable
        visibleState: root.screenshotVisible

        onScreenshotClosed: {
            root.screenshotVisible = false;
        }
    }

    WallpaperOverlay {
        // This will sit on the WlrLayer.Background
    }

    DesktopClock {
        // Draggable analog clock on the WlrLayer.Bottom
    }
    DesktopCalender {
        // Draggable analog clock on the WlrLayer.Bottom
    }

    Overview {
        visibleState: root.overviewVisible
        onCloseRequested: {
            root.overviewVisible = false;
        }
    }

    // Launcher is now inside TopPills.qml
    NotificationDaemon {
        id: notifDaemon
    }

    TopPills {
        id: topPills
        onToggleFloatingSettings: floatingSettings.toggle()
        onPopupOpened: {
            root.overviewVisible = false;
            root.screenshotVisible = false;
        }
        onOpenOverviewRequested: {
            root.overviewVisible = true;
        }
    }

    SettingsWindow {
        id: floatingSettings
        onRequestWidgetToggle: topPills.toggleSettings()
    }
}
