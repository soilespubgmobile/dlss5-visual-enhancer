import QtQuick
import QtQuick.Window
import QtQuick.Controls as QQC2
import ".."
import "../controls"

Rectangle {
    id: root
    // Native window buttons retain their Windows positions in RTL locales.
    LayoutMirroring.enabled: false
    LayoutMirroring.childrenInherit: true
    property var appBridge: null
    property var windowRef: null
    readonly property bool compact: width < 1320
    readonly property bool narrow: width < 1140
    property bool modelsOpen: false
    signal modelsRequested()
    signal importPresetRequested()
    signal exportPresetRequested()
    signal slotsRequested()
    property Item presetOpener: null
    property Item helpOpener: null
    readonly property bool submenuVisible: presetsMenu.visible || helpMenu.visible
    onSubmenuVisibleChanged: updateChromeRects()

    function restorePresetFocus() {
        if (presetOpener) presetOpener.forceActiveFocus()
    }

    function finishMenu(menu, opener) {
        menu.currentIndex = -1
        if (menu.restoreKeyboardFocus) {
            if (opener) opener.forceActiveFocus()
        } else if (opener && opener.activeFocus) {
            opener.focus = false
            if (windowRef) windowRef.contentItem.forceActiveFocus(Qt.MouseFocusReason)
        }
    }

    function togglePresets(button) {
        helpOpener = null
        helpMenu.close()
        presetOpener = button
        if (presetsMenu.opened) presetsMenu.close()
        else {
            // Keep the popup below the native title-bar drag region.
            const top = button.mapToItem(root, 0, 0).y
            presetsMenu.popup(button, button.labelCenterX - presetsMenu.width / 2, root.height - top + 4)
        }
    }

    function toggleHelp(button) {
        presetsMenu.close()
        helpOpener = button
        if (helpMenu.opened) helpMenu.close()
        else {
            const top = button.mapToItem(root, 0, 0).y
            helpMenu.popup(button, button.labelCenterX - helpMenu.width / 2, root.height - top + 4)
        }
    }

    height: 50
    color: Theme.bgSurface
    border.color: Theme.borderSubtle
    border.width: 1

    // QML drag/double-click fallbacks. On Windows the native filter reports
    // HTCAPTION for empty header space, so the OS owns drag, double-click
    // maximize and edge snap there (double-handling would fight it). The
    // fallbacks stay live until hit-test rects are published, so the header
    // is never dead while the filter is still blind.
    readonly property bool nativeChrome: windowRef && windowRef.nativeChromeActive === true && windowRef.chromeRectsReady === true
    MouseArea {
        anchors.fill: parent; z: 0
        onPressed: { if (!root.nativeChrome && windowRef && windowRef.visibility !== Window.Maximized && windowRef.visibility !== Window.FullScreen) windowRef.startSystemMove() }
        onDoubleClicked: {
            if (!windowRef || root.nativeChrome) return
            root.toggleMaximize()
        }
    }

    // Native maximize/restore (the OS filter supplies a real frame behind the
    // frameless visuals, so geometry, taskbar and animations are correct).
    function toggleMaximize() {
        if (!windowRef) return
        if (windowRef.visibility === Window.Maximized || windowRef.visibility === Window.FullScreen) windowRef.showNormal()
        else windowRef.showMaximized()
    }

    // Window-relative chrome rects (DIPs) for the native hit-test filter, so
    // snap/min/max/close land exactly on the drawn buttons and tab clicks
    // still reach QML. Refreshed whenever the header layout changes.
    function updateChromeRects() {
        if (!windowRef || !windowRef.contentItem) return
        var p
        p = minBtn.mapToItem(windowRef.contentItem, 0, 0)
        windowRef.minBtnRect = Qt.rect(p.x, p.y, Math.max(minBtn.width, minBtn.implicitWidth), Math.max(minBtn.height, minBtn.implicitHeight))
        p = maxBtn.mapToItem(windowRef.contentItem, 0, 0)
        windowRef.maxBtnRect = Qt.rect(p.x, p.y, Math.max(maxBtn.width, maxBtn.implicitWidth), Math.max(maxBtn.height, maxBtn.implicitHeight))
        p = closeBtn.mapToItem(windowRef.contentItem, 0, 0)
        windowRef.closeBtnRect = Qt.rect(p.x, p.y, Math.max(closeBtn.width, closeBtn.implicitWidth), Math.max(closeBtn.height, closeBtn.implicitHeight))
        p = navTabs.mapToItem(windowRef.contentItem, 0, 0)
        // While a submenu is open, deliver empty title-bar clicks to Qt so
        // the popup can dismiss them before Windows starts a caption drag.
        if (submenuVisible) {
            p = root.mapToItem(windowRef.contentItem, 0, 0)
            windowRef.navTabsRect = Qt.rect(p.x, p.y, root.width, root.height)
        } else {
            windowRef.navTabsRect = Qt.rect(p.x, p.y, navTabs.width, navTabs.height)
        }
        windowRef.chromeRectsReady = windowRef.minBtnRect.width > 0 && windowRef.maxBtnRect.width > 0
            && windowRef.closeBtnRect.width > 0 && windowRef.navTabsRect.width > 0
            && windowRef.minBtnRect.height > 0 && windowRef.maxBtnRect.height > 0
            && windowRef.closeBtnRect.height > 0 && windowRef.navTabsRect.height > 0
    }
    onWidthChanged: Qt.callLater(updateChromeRects)
    Component.onCompleted: Qt.callLater(updateChromeRects)
    Connections {
        target: rightArea
        function onWidthChanged() { Qt.callLater(root.updateChromeRects) }
    }
    Connections {
        target: navTabs
        function onWidthChanged() { Qt.callLater(root.updateChromeRects) }
    }
    Connections {
        target: windowRef
        function onHeightChanged() { Qt.callLater(root.updateChromeRects) }
        function onWidthChanged() { Qt.callLater(root.updateChromeRects) }
        // Maximize/restore settles geometry asynchronously; refresh once the
        // state lands so the native filter never aims at pre-toggle rects.
        function onVisibilityChanged() { Qt.callLater(root.updateChromeRects) }
    }

    Row {
        id: brand; z: 2
        anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
        Image {
            objectName: "applicationBrandIcon"
            source: Qt.resolvedUrl("../assets/relios-vision.png")
            sourceSize: Qt.size(112, 112)
            width: 28; height: 28
            fillMode: Image.PreserveAspectFit
            smooth: true
            anchors.verticalCenter: parent.verticalCenter
        }
        Text { visible: root.width >= 700; text: "Relios Vision"; font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeTitle; font.weight: Font.Normal; color: Theme.textPrimary; anchors.verticalCenter: parent.verticalCenter }
    }

    Row {
        id: rightArea; z: 2
        anchors.right: parent.right; anchors.rightMargin: 8; anchors.verticalCenter: parent.verticalCenter; spacing: root.compact ? 6 : 10
        Row {
            spacing: 2
            // Window-chrome buttons: vector icons, no hover tooltips (they sit
            // at y=0 where an above-anchored popup would clip outside the window).
            // On Windows the native filter hit-tests these rects (snap flyout,
            // system press animations); the QML handlers are the fallback path
            // for the pre-rects blind window only. The nativeChrome guard keeps
            // single ownership: without it a transition-frame double delivery
            // would toggle maximize twice (apparent no-op) or fight the OS.
            // Minimize intentionally has no nativeChrome guard: minimize is
            // idempotent, and if the OS hit-test claimed the click QML never
            // receives it — so a click arriving here always means the OS did
            // NOT claim it (mapping miss) and minimizing is the right action.
            // maxBtn/closeBtn keep the guard (toggle/close double-delivery).
            AppIconButton { id: minBtn; objectName: "windowMinimizeButton"; iconName: "minimize"; showTooltip: false; onClicked: { if (windowRef) windowRef.showMinimized() } }
            AppIconButton {
                id: maxBtn
                objectName: "windowMaximizeButton"
                iconName: windowRef && (windowRef.visibility === Window.Maximized || windowRef.visibility === Window.FullScreen) ? "restore_window" : "maximize"
                showTooltip: false
                nativeHovered: root.nativeChrome && windowRef.nativeHoveredButton === "maximize"
                onClicked: { if (root.nativeChrome) return; root.toggleMaximize() }
            }
            AppIconButton {
                id: closeBtn
                objectName: "windowCloseButton"
                iconName: "close"
                showTooltip: false
                hoverBackgroundColor: Theme.danger
                hoverBorderColor: Theme.danger
                pressedBackgroundColor: Theme.dangerPressed
                nativeHovered: root.nativeChrome && windowRef.nativeHoveredButton === "close"
                onClicked: { if (root.nativeChrome) return; if (windowRef) windowRef.close() }
            }
        }
    }

    // Menu-style navigation: plain compact text tabs grouped on the left,
    // active tab shown by accent text color only (no button chrome).
    Row {
        id: navTabs; z: 3
        objectName: "headerNavigation"
        anchors.left: brand.right; anchors.leftMargin: 16
        anchors.verticalCenter: parent.verticalCenter
        spacing: 4
        readonly property real availableWidth: Math.max(0, rightArea.x - x - 8)
        readonly property real buttonPadding: 16
        readonly property real labelScale: Math.min(1, Math.max(0, availableWidth - (tabs.length - 1) * spacing - tabs.length * buttonPadding) / Math.max(1, navigationMetrics.width + tabs.length))
        readonly property var tabs: [
            { id:"neural-rendering", full:qsTranslate("App", "Neural Rendering"), short:qsTranslate("App", "Neural") },
            { id:"presets", full:qsTranslate("App", "Presets"), short:qsTranslate("App", "Presets") },
            { id:"compare", full:qsTranslate("App", "Compare"), short:qsTranslate("App", "Compare") },
            { id:"models", full:qsTranslate("App", "Models"), short:qsTranslate("App", "Models") },
            { id:"settings", full:qsTranslate("App", "Settings"), short:qsTranslate("App", "Settings") },
            { id:"help", full:qsTranslate("App", "Help"), short:qsTranslate("App", "Help") }
        ]
        TextMetrics {
            id: navigationMetrics
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeLabel
            text: navTabs.tabs.map(function(tab) { return root.compact ? tab.short : tab.full }).join("")
        }
        Repeater {
            id: navigationButtons
            model: navTabs.tabs
            Item {
                id: tabBtn
                objectName: "header-" + modelData.id
                activeFocusOnTab: true
                height: 28
                width: navTabs.buttonPadding + Math.ceil(tabLabel.implicitWidth * navTabs.labelScale)
                readonly property real labelCenterX: tabLabel.mapToItem(tabBtn, tabLabel.width / 2, 0).x
                readonly property bool isActive: modelData.id === "presets" ? presetsMenu.opened
                    : modelData.id === "help" ? helpMenu.opened
                    : modelData.id === "models" ? root.modelsOpen
                    : appBridge ? appBridge.activeTab === modelData.id : false
                readonly property var transfers: modelData.id === "models" && root.appBridge ? root.appBridge.models : null
                readonly property bool transferring: transfers ? transfers.transfersActive : false
                function activate() {
                    forceActiveFocus()
                    if (modelData.id === "presets") root.togglePresets(tabBtn)
                    else if (modelData.id === "help") root.toggleHelp(tabBtn)
                    else {
                        presetsMenu.close()
                        root.helpOpener = null
                        helpMenu.close()
                        if (modelData.id === "models") root.modelsRequested()
                        else if (appBridge) appBridge.activeTab = modelData.id
                    }
                }
                Keys.onPressed: (event) => {
                    if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter || event.key === Qt.Key_Space ||
                        ((modelData.id === "presets" || modelData.id === "help") && event.key === Qt.Key_Down)) {
                        activate(); event.accepted = true
                    } else if (event.key === Qt.Key_Left || event.key === Qt.Key_Right) {
                        const next = (index + (event.key === Qt.Key_Left ? -1 : 1) + navigationButtons.count) % navigationButtons.count
                        navigationButtons.itemAt(next).forceActiveFocus()
                        event.accepted = true
                    }
                }
                Text {
                    id: tabLabel
                    anchors.centerIn: parent
                    width: Math.min(implicitWidth, Math.max(0, tabBtn.width - navTabs.buttonPadding))
                    elide: Text.ElideRight
                    text: root.compact ? modelData.short : modelData.full
                    font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLabel
                    font.weight: Font.Normal
                    color: tabBtn.isActive || tabBtn.transferring ? Theme.accent : (tabMouse.containsMouse ? Theme.textPrimary : Theme.textSecondary)
                }
                Rectangle {
                    id: transferIndicator
                    objectName: modelData.id === "models" ? "models-transfer-indicator" : ""
                    visible: tabBtn.transferring
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    anchors.leftMargin: 8
                    anchors.rightMargin: 8
                    height: 3
                    radius: 1.5
                    color: Theme.borderDefault
                    clip: true
                    readonly property bool indeterminate: tabBtn.transfers ? tabBtn.transfers.transferIndeterminate : false
                    readonly property real progress: tabBtn.transfers ? tabBtn.transfers.transferProgress : 0
                    property real sweep: 0
                    Rectangle {
                        height: parent.height
                        radius: parent.radius
                        color: Theme.accent
                        width: transferIndicator.indeterminate ? Math.max(12, parent.width * 0.35) : parent.width * Math.max(0, Math.min(1, transferIndicator.progress))
                        x: transferIndicator.indeterminate ? (parent.width + width) * transferIndicator.sweep - width : 0
                    }
                    NumberAnimation on sweep {
                        running: transferIndicator.visible && transferIndicator.indeterminate
                        from: 0; to: 1; duration: 1300; loops: Animation.Infinite
                    }
                    SequentialAnimation on opacity {
                        running: transferIndicator.visible && !transferIndicator.indeterminate
                        loops: Animation.Infinite
                        NumberAnimation { from: 1; to: 0.55; duration: 900 }
                        NumberAnimation { from: 0.55; to: 1; duration: 900 }
                    }
                }
                Accessible.role: modelData.id === "presets" || modelData.id === "help" ? Accessible.Button : Accessible.PageTab
                Accessible.name: modelData.full
                Accessible.description: tabBtn.transferring ? qsTranslate("App", "Downloading") : ""
                Accessible.onPressAction: activate()
                MouseArea {
                    id: tabMouse; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: tabBtn.activate()
                }
            }
        }
    }

    component HeaderMenuAction: QQC2.MenuItem {
        id: action
        required property var ownerMenu
        implicitHeight: 34
        Keys.onEscapePressed: { ownerMenu.restoreKeyboardFocus = true; ownerMenu.close() }
        leftPadding: 10; rightPadding: 10
        contentItem: Text {
            objectName: "headerMenuText"
            text: action.text
            opacity: action.enabled ? 1 : 0.4
            font.family: Theme.fontFamily; font.pixelSize: Theme.fontSizeLabel
            color: Theme.textPrimary
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
        background: Rectangle { color: action.highlighted ? Theme.bgHover : "transparent"; radius: Theme.radiusSmall }
    }

    QQC2.Menu {
        id: presetsMenu
        property bool restoreKeyboardFocus: false
        objectName: "presetsMenu"
        popupType: QQC2.Popup.Item
        focus: true
        margins: 8
        padding: 4
        width: Math.ceil(Math.max(slotsAction.implicitWidth, importAction.implicitWidth, exportAction.implicitWidth)) + leftPadding + rightPadding
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        background: Rectangle { color: Theme.bgSurface; border.color: Theme.borderDefault; radius: Theme.radiusMedium }
        HeaderMenuAction {
            id: slotsAction
            ownerMenu: presetsMenu
            objectName: "reliosSlotsAction"
            text: "Kayıtlı ayarlarım…"
            enabled: root.appBridge !== null
            onTriggered: {
                presetsMenu.restoreKeyboardFocus = true
                presetsMenu.close()
                Qt.callLater(function() { root.slotsRequested() })
            }
        }
        HeaderMenuAction {
            id: importAction
            ownerMenu: presetsMenu
            objectName: "importPresetAction"
            text: qsTranslate("App", "Import Preset")
            enabled: root.appBridge && root.appBridge.operationState === "Idle"
            onTriggered: {
                presetsMenu.restoreKeyboardFocus = true
                presetsMenu.close()
                Qt.callLater(function() { root.importPresetRequested() })
            }
        }
        HeaderMenuAction {
            id: exportAction
            ownerMenu: presetsMenu
            objectName: "exportPresetAction"
            text: qsTranslate("App", "Export Preset")
            enabled: root.appBridge !== null
            onTriggered: {
                presetsMenu.restoreKeyboardFocus = true
                presetsMenu.close()
                Qt.callLater(function() { root.exportPresetRequested() })
            }
        }
        onOpened: {
            restoreKeyboardFocus = false
            currentIndex = 0
            slotsAction.forceActiveFocus()
        }
        onClosed: root.finishMenu(presetsMenu, root.presetOpener)
    }

    QQC2.Menu {
        id: helpMenu
        property bool restoreKeyboardFocus: false
        objectName: "helpMenu"
        popupType: QQC2.Popup.Item
        focus: true
        margins: 8
        padding: 4
        width: Math.ceil(logsAction.implicitWidth) + leftPadding + rightPadding
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        background: Rectangle { color: Theme.bgSurface; border.color: Theme.borderDefault; radius: Theme.radiusMedium }
        HeaderMenuAction {
            id: logsAction
            ownerMenu: helpMenu
            objectName: "helpLogsAction"
            text: qsTranslate("App", "Logs")
            enabled: root.appBridge !== null
            onTriggered: {
                helpMenu.restoreKeyboardFocus = true
                helpMenu.close()
                if (root.appBridge) root.appBridge.openFolder(root.appBridge.currentLogPath)
            }
        }
        onOpened: {
            restoreKeyboardFocus = false
            currentIndex = 0
            logsAction.forceActiveFocus()
        }
        onClosed: root.finishMenu(helpMenu, root.helpOpener)
    }
}
