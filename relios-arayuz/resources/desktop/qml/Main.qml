import QtQuick
import QtQuick.Window
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import "."
import "components"
import "views"
import "controls"

Window {
    id: appWindow
    property string workspaceTab: "neural-rendering"
    property bool restoringModelsTab: false
    function showModels() {
        if (typeof backend !== "undefined" && backend && backend.activeTab === "models") {
            restoringModelsTab = true
            backend.activeTab = workspaceTab
            restoringModelsTab = false
        }
        modelsDialog.open()
    }
    Component.onCompleted: {
        if (typeof backend !== "undefined" && backend) {
            if (backend.activeTab === "models") Qt.callLater(showModels)
            else workspaceTab = backend.activeTab
        }
    }
    Connections {
        target: typeof backend !== "undefined" ? backend : null
        function onActiveTabChanged() {
            if (appWindow.restoringModelsTab) return
            if (backend.activeTab === "models") appWindow.showModels()
            else {appWindow.workspaceTab = backend.activeTab; modelsDialog.close()}
        }
    }

    // The application applies the saved rectangle before creating the native
    // window. Continuous geometry bindings would undo OS resizing and snapping.
    width: 1440
    height: 920
    // Allow half/third-width and quarter-height Windows snap zones.
    minimumWidth: 500
    minimumHeight: 330
    // The application reveals the fully prepared window maximized.
    flags: Qt.Window | Qt.FramelessWindowHint
    title: "Relios Vision"
    color: Theme.bgBase
    LayoutMirroring.enabled: Qt.application.layoutDirection === Qt.RightToLeft
    LayoutMirroring.childrenInherit: true

    readonly property var windowRef: appWindow
    property bool closeApproved: false

    // Chrome hit-test rects (window-relative DIPs) published by HeaderBar for
    // the native Windows filter. Default empty = filter falls back to client.
    property rect minBtnRect: Qt.rect(0, 0, 0, 0)
    property rect maxBtnRect: Qt.rect(0, 0, 0, 0)
    property rect closeBtnRect: Qt.rect(0, 0, 0, 0)
    property rect navTabsRect: Qt.rect(0, 0, 0, 0)
    property bool chromeRectsReady: false
    property bool nativeChromeActive: false
    property string nativeHoveredButton: ""

    function saveWindowLayout() {
        if (typeof backend !== "undefined" && backend)
            backend.saveWindowLayout(appWindow.x, appWindow.y, appWindow.width, appWindow.height, appWindow.visibility === Window.Maximized)
    }

    onClosing: (close) => {
        saveWindowLayout()
        if (!closeApproved && typeof backend !== "undefined" && backend && (backend.operationState !== "Idle" || (backend.compare && (backend.compare.busy || backend.compare.loading)))) {
            close.accepted = false
            closeDialog.open()
        } else {
            // Native decoder and GPU cleanup may outlast the close event.
            // Remove the window immediately once the close is accepted.
            appWindow.hide()
        }
    }

    Shortcut {
        sequence: "F11"
        onActivated: {
            if (appWindow.visibility === Window.FullScreen) appWindow.showNormal(); else appWindow.showFullScreen()
        }
    }
    Shortcut {
        sequence: "Ctrl+Shift+F"
        onActivated: { if (typeof backend !== "undefined" && backend) backend.focusPreview = !backend.focusPreview }
    }

    // Global editing shortcuts below must never steal keys from text
    // editors (path fields use TextInput).
    // NOTE: guards live in `enabled` (not only in onActivated) so a
    // disabled Shortcut never consumes the key — TextInput keeps native
    // Ctrl+V / Delete / Space behavior while editing.
    readonly property bool isTextEditing: activeFocusItem instanceof TextInput || activeFocusItem instanceof TextEdit
    readonly property bool isBatchTab: typeof backend !== "undefined" && backend ? backend.activeTab === "neural-rendering" : false

    function textEditingFocused() {
        return appWindow.isTextEditing
    }

    function batchTabActive() {
        return appWindow.isBatchTab
    }

    // Ctrl+V: paste Explorer files / screenshots into the active batch tab.
    Shortcut {
        sequence: "Ctrl+V"
        enabled: appWindow.isBatchTab && !appWindow.isTextEditing
        onActivated: {
            if (appWindow.textEditingFocused() || !appWindow.batchTabActive()) return
            if (typeof backend !== "undefined" && backend) backend.pasteFromClipboard()
        }
    }
    // Delete: same as the Clear All queue button (active tab only).
    Shortcut {
        sequence: "Delete"
        enabled: appWindow.isBatchTab && !appWindow.isTextEditing
        onActivated: {
            if (appWindow.textEditingFocused() || !appWindow.batchTabActive()) return
            if (typeof backend !== "undefined" && backend) backend.clearActiveQueue()
        }
    }

    Column {
        anchors.fill: parent
        HeaderBar {
            id: header
            width: parent.width
            appBridge: typeof backend !== "undefined" ? backend : null
            windowRef: appWindow
            modelsOpen: modelsDialog.visible
            onModelsRequested: appWindow.showModels()
            onImportPresetRequested: presetDialogs.openImport()
            onExportPresetRequested: presetDialogs.openExport()
            onSlotsRequested: presetDialogs.openSlots()
        }

        Item {
            id: workspace
            width: parent.width
            height: parent.height - header.height
            clip: true
            StackLayout {
                anchors.fill: parent
                currentIndex: {
                    if (typeof backend === "undefined" || !backend) return 0
                    var tab = appWindow.workspaceTab
                    if (tab === "neural-rendering") return 0
                    if (tab === "settings") return 1
                    if (tab === "help") return 2
                    if (tab === "models") return 3
                    if (tab === "compare") return 4
                    return 0
                }
                NeuralRenderingView { appBridge: typeof backend !== "undefined" ? backend : null }
                Loader {
                    property bool visited: false
                    readonly property bool selected: StackLayout.isCurrentItem
                    active: visited
                    onSelectedChanged: { if (selected) visited = true }
                    Component.onCompleted: { if (selected) visited = true }
                    sourceComponent: SettingsView { objectName: "settingsView"; appBridge: typeof backend !== "undefined" ? backend : null }
                }
                Loader {
                    property bool visited: false
                    readonly property bool selected: StackLayout.isCurrentItem
                    active: visited
                    onSelectedChanged: { if (selected) visited = true }
                    Component.onCompleted: { if (selected) visited = true }
                    sourceComponent: AboutView { appBridge: typeof backend !== "undefined" ? backend : null }
                }
                Item {} // Former Models page slot; Models now opens over the workspace.
                Loader {
                    property bool visited: false
                    readonly property bool selected: StackLayout.isCurrentItem
                    active: visited
                    onSelectedChanged: { if (selected) visited = true }
                    Component.onCompleted: { if (selected) visited = true }
                    sourceComponent: CompareView { appBridge: typeof backend !== "undefined" ? backend : null }
                }
            }
        }
    }

    QQC2.Dialog {
        id: modelsDialog; objectName: "modelsDialog"
        parent: QQC2.Overlay.overlay; anchors.centerIn: parent
        width: Math.min(680, parent ? parent.width - 32 : 680)
        height: Math.min(parent ? parent.height - 32 : 600, modelsContents.implicitHeight + 94)
        modal: true; focus: true; padding: 0
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        title: qsTranslate("App", "Models")
        header: Rectangle {
            height: 44; color: Theme.bgSurface; border.color: Theme.borderDefault
            Text {objectName:"models-title";anchors.left:parent.left;anchors.leftMargin:12;anchors.verticalCenter:parent.verticalCenter;text:modelsDialog.title;color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSubtitle;font.weight:Font.DemiBold}
            Rectangle {anchors.bottom:parent.bottom;width:parent.width;height:1;color:Theme.borderSubtle}
        }
        background: Rectangle {color:Theme.bgSurface;radius:0;border.width:1;border.color:Theme.borderDefault}
        contentItem: ModelsView {id:modelsContents;objectName:"modelsView";color:"transparent";appBridge:typeof backend!=="undefined"?backend:null}
        footer: Item {
            height: 50
            AppButton {objectName:"modelsClose";anchors.right:parent.right;anchors.rightMargin:12;anchors.verticalCenter:parent.verticalCenter;text:qsTranslate("App","Close");buttonHeight:30;onClicked:modelsDialog.close()}
        }
    }

    PresetDialogs {
        id: presetDialogs
        objectName: "presetDialogs"
        appBridge: typeof backend !== "undefined" ? backend : null
        onFinished: header.restorePresetFocus()
    }

    ExportDialog {
        id: exportDialog
        appBridge: typeof backend !== "undefined" ? backend : null
    }
    Connections {
        target: typeof backend !== "undefined" ? backend : null
        function onBatchExportRequested(contextKey) {
            exportDialog.openForContext(contextKey)
        }
    }

    // QML resize hit zones (fallback where the native filter is inactive; on
    // Windows the OS owns the frame edges). Disabled while maximized/fullscreen.
    property bool qmlResizeActive: !(appWindow.nativeChromeActive === true && appWindow.chromeRectsReady === true) && appWindow.visibility !== Window.Maximized && appWindow.visibility !== Window.FullScreen
    MouseArea { z:10000; visible: qmlResizeActive; anchors.left:parent.left; anchors.top:parent.top; anchors.bottom:parent.bottom; width:6; cursorShape:Qt.SizeHorCursor; onPressed: { appWindow.startSystemResize(Qt.LeftEdge) } }
    MouseArea { z:10000; visible: qmlResizeActive; anchors.right:parent.right; anchors.top:parent.top; anchors.bottom:parent.bottom; width:6; cursorShape:Qt.SizeHorCursor; onPressed: { appWindow.startSystemResize(Qt.RightEdge) } }
    MouseArea { z:10000; visible: qmlResizeActive; anchors.top:parent.top; anchors.left:parent.left; anchors.right:parent.right; height:6; cursorShape:Qt.SizeVerCursor; onPressed: { appWindow.startSystemResize(Qt.TopEdge) } }
    MouseArea { z:10000; visible: qmlResizeActive; anchors.bottom:parent.bottom; anchors.left:parent.left; anchors.right:parent.right; height:6; cursorShape:Qt.SizeVerCursor; onPressed: { appWindow.startSystemResize(Qt.BottomEdge) } }
    MouseArea { z:10001; visible: qmlResizeActive; anchors.left:parent.left; anchors.top:parent.top; width:10; height:10; cursorShape:Qt.SizeFDiagCursor; onPressed: { appWindow.startSystemResize(Qt.LeftEdge|Qt.TopEdge) } }
    MouseArea { z:10001; visible: qmlResizeActive; anchors.right:parent.right; anchors.top:parent.top; width:10; height:10; cursorShape:Qt.SizeBDiagCursor; onPressed: { appWindow.startSystemResize(Qt.RightEdge|Qt.TopEdge) } }
    MouseArea { z:10001; visible: qmlResizeActive; anchors.left:parent.left; anchors.bottom:parent.bottom; width:10; height:10; cursorShape:Qt.SizeBDiagCursor; onPressed: { appWindow.startSystemResize(Qt.LeftEdge|Qt.BottomEdge) } }
    MouseArea { z:10001; visible: qmlResizeActive; anchors.right:parent.right; anchors.bottom:parent.bottom; width:10; height:10; cursorShape:Qt.SizeFDiagCursor; onPressed: { appWindow.startSystemResize(Qt.RightEdge|Qt.BottomEdge) } }

    QQC2.Dialog {
        id: closeDialog
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: 420
        z: 20000
        focus: true
        modal: true
        closePolicy: QQC2.Popup.CloseOnEscape
        footer: Item {
            implicitHeight: 48
            Row {
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter; spacing: 8
                AppButton { text: qsTranslate("App", "No"); onClicked: closeDialog.reject() }
                AppButton { text: qsTranslate("App", "Yes"); variant: "danger"; onClicked: closeDialog.accept() }
            }
        }
        leftPadding: 20
        rightPadding: 20
        topPadding: 16
        bottomPadding: 12
        spacing: 8
        // Borderless custom header: the default Dialog title chrome draws
        // its own light separator line under the title.
        header: QQC2.Label {
            text: qsTranslate("App", "Operation still active")
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: Theme.fontSizeTitle
            font.weight: Font.Bold
            leftPadding: 20
            rightPadding: 20
            topPadding: 16
            bottomPadding: 4
        }
        contentItem: Text {
            text: qsTranslate("App", "A render, preview, or scan is still active. Cancel it and exit?")
            color: Theme.textPrimary; font.family: Theme.fontFamily; wrapMode: Text.WordWrap; width: 360
        }
        // Borderless: the previous border.color (light gray) read as a
        // white outline around the whole box against the dark surface.
        background: Rectangle { color: Theme.bgSurface; border.width: 0; radius: Theme.radiusLarge }
        onAccepted: { appWindow.closeApproved = true; appWindow.close() }
    }
}
