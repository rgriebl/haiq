import QtQuick
import QtQuick.Controls
import QtQuick.Window
import QtWayland.Compositor
import QtWayland.Compositor.WlShell
import QtWayland.Compositor.XdgShell
import org.griebl.haiq 1.0

Page {
    id: root
    focusPolicy: Qt.StrongFocus

    WaylandCompositor {
        id: waylandCompositor

        // Shell surface extension. Needed to provide a window concept for Wayland clients.
        // I.e. requests and events for maximization, minimization, resizing, closing etc.
        XdgShell {
            onToplevelCreated: (xdgToplevel, xdgSurface) => {
                                   console.log("new tl")
                                   screen.handleShellSurface(xdgSurface)
                                   console.log(xdgToplevel.decorationMode)
                                   xdgToplevel.sendMaximized(Qt.size(screen.availableGeometry.width,
                                                                     screen.availableGeometry.height))
                               }
        }

        XdgOutputManagerV1 {
            WaylandOutput {
                id: screen
                position: Qt.point(0, 0)
                window: root.Window.window
                sizeFollowsWindow: true
                compositor: waylandCompositor

                XdgOutputV1 {
                    name: "SCREEN-1"
                    logicalPosition: screen.position
                    logicalSize: Qt.size(root.width, root.height)
                }
//                compositor: waylandCompositor
//                sizeFollowsWindow: true
//                //geometry:  Qt.rect(0, 0, root.width, root.height)
                availableGeometry: Qt.rect(0, 0, root.width, root.height)

                property ListModel shellSurfaces: ListModel {}

                function handleShellSurface(shellSurface) {
                    shellSurfaces.append({shellSurface: shellSurface});
                }
            }
        }

        XdgDecorationManagerV1 {
            preferredMode: XdgToplevel.ServerSideDecoration
        }

        // Extension for Input Method (QT_IM_MODULE) support at compositor-side
        TextInputManager {}
        socketName: "haiq-wayland-0"

        property bool startedFireFox: false

        onCreatedChanged: {
            if (created && !startedFireFox) {
                startedFireFox = true
                console.log("Running firefox on Wayland socket " + socketName)
                AppStarter.addApp([ "firefox", "about:home" ],
                                  {   "MOZ_ENABLE_WAYLAND": "1",
                                      "MOZ_GTK_TITLEBAR_DECORATION": "server",
                                      "XDG_CURRENT_DESKTOP": "KDE",
                                      "QT_WAYLAND_DISABLE_WINDOWDECORATION": "1",
                                      "WAYLAND_DISPLAY": socketName });
            }
        }
    }

    Repeater {
        anchors.fill: parent
        model: screen.shellSurfaces
        ShellSurfaceItem {
            anchors.fill: parent
            shellSurface: modelData
            touchEventsEnabled: true
            onSurfaceDestroyed: screen.shellSurfaces.remove(index)
            autoCreatePopupItems: true
        }
    }

    Component.onCompleted: {
        console.log("WL socket: ", waylandCompositor.socketName)
    }
}
