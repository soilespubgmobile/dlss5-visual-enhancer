import QtQuick
import QtQuick.Window
import QtQuick.Dialogs
import QtQuick.Controls as QQC2
import QtCore as Core
import ".."
import "../controls"

Item {
    id: root
    property var appBridge: null
    signal finished()

    function openImport() {
        if (appBridge) importDialog.open()
    }

    function openExport() {
        if (!appBridge) return
        var folder = saveDialog.currentFolder.toString()
        if (folder.length === 0)
            folder = Core.StandardPaths.writableLocation(Core.StandardPaths.DocumentsLocation).toString()
        var filename = "preset_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_hh-mm-ss") + ".json"
        saveDialog.selectedFile = folder.replace(/\/?$/, "/") + filename
        saveDialog.open()
    }

    // ---- Relios: saved settings slots ("Ayarım 1..5") stored as JSON presets
    // in the "ayarlar" folder next to the program, plus Turkish as the
    // first-run interface language.
    readonly property int slotCount: 5
    readonly property string slotFolder: Qt.resolvedUrl("../../../../ayarlar/").toString()
    function slotUrl(i) { return slotFolder + "Ayarim-" + (i + 1) + ".json" }
    function slotInfo(i) {
        var all = {}
        try { all = JSON.parse(reliosPrefs.slots || "{}") } catch (e) { all = {} }
        return all[String(i)] || null
    }
    function setSlotInfo(i, info) {
        var all = {}
        try { all = JSON.parse(reliosPrefs.slots || "{}") } catch (e) { all = {} }
        all[String(i)] = info
        reliosPrefs.slots = JSON.stringify(all)
        reliosPrefs.sync()
        slotRevision += 1
    }
    property int slotRevision: 0
    function openSlots() { if (appBridge) slotsDialog.open() }
    function saveSlot(i) {
        if (!appBridge) return
        var ok = appBridge.exportPresetTo("Ayarım " + (i + 1), slotUrl(i)).length > 0
        if (ok) setSlotInfo(i, { saved: Qt.formatDateTime(new Date(), "dd.MM.yyyy HH:mm") })
        feedback.success = ok
        feedback.message = ok ? "Ayarım " + (i + 1) + " kaydedildi."
                              : "Kaydedilemedi. Program klasöründe \"ayarlar\" klasörü olmalı."
        feedback.open(); feedbackTimer.restart()
    }
    function loadSlot(i) {
        if (!appBridge) return
        var ok = appBridge.importPreset(slotUrl(i))
        feedback.success = ok
        feedback.message = ok ? "Ayarım " + (i + 1) + " yüklendi." : (appBridge.presetStatus || "Yüklenemedi.")
        feedback.open(); feedbackTimer.restart()
        if (ok) slotsDialog.close()
    }
    function applyTurkishDefault() {
        if (!appBridge || reliosPrefs.turkishApplied) return
        reliosPrefs.turkishApplied = true
        reliosPrefs.sync()
        if (appBridge.language !== "pl") appBridge.language = "pl"
    }
    onAppBridgeChanged: Qt.callLater(applyTurkishDefault)
    Component.onCompleted: Qt.callLater(applyTurkishDefault)

    Core.Settings {
        id: reliosPrefs
        category: "relios"
        property bool turkishApplied: false
        property string slots: "{}"
    }

    QQC2.Dialog {
        id: slotsDialog
        objectName: "reliosSlotsDialog"
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(520, parent.width - 40)
        modal: true
        focus: true
        dim: true
        closePolicy: QQC2.Popup.CloseOnEscape
        padding: 20
        header: QQC2.Label {
            text: "Kayıtlı ayarlarım"
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
            padding: 20
            bottomPadding: 0
        }
        contentItem: Column {
            spacing: 10
            Text {
                width: parent.width
                text: "Şu anki ayarlarını bir yuvaya kaydet, istediğinde tek tıkla geri yükle. Dosya olarak saklamak ya da başka bilgisayara taşımak için alttaki düğmeleri kullan."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            Repeater {
                model: root.slotCount
                delegate: Rectangle {
                    id: slotRow
                    required property int index
                    readonly property var info: { root.slotRevision; return root.slotInfo(index) }
                    width: parent.width
                    height: 48
                    radius: Theme.radiusMedium
                    color: Theme.bgInput
                    border.color: Theme.borderSubtle
                    Column {
                        anchors.left: parent.left; anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text {
                            text: "Ayarım " + (slotRow.index + 1)
                            color: Theme.textPrimary
                            font.family: Theme.fontFamily
                            font.pixelSize: 14
                            font.weight: Font.Medium
                        }
                        Text {
                            text: slotRow.info ? "Kaydedildi: " + slotRow.info.saved : "Boş"
                            color: slotRow.info ? Theme.textSecondary : Theme.textMuted
                            font.family: Theme.fontFamily
                            font.pixelSize: 11
                        }
                    }
                    Row {
                        anchors.right: parent.right; anchors.rightMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6
                        AppButton {
                            text: "Yükle"
                            enabled: slotRow.info !== null && root.appBridge && root.appBridge.operationState === "Idle"
                            onClicked: root.loadSlot(slotRow.index)
                        }
                        AppButton {
                            text: "Kaydet"
                            variant: "primary"
                            onClicked: root.saveSlot(slotRow.index)
                        }
                    }
                }
            }
        }
        footer: Item {
            implicitHeight: 56
            Row {
                anchors.left: parent.left; anchors.leftMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8
                AppButton {
                    text: "Dosyadan aç…"
                    enabled: root.appBridge && root.appBridge.operationState === "Idle"
                    onClicked: { slotsDialog.close(); root.openImport() }
                }
                AppButton {
                    text: "Dosyaya kaydet…"
                    onClicked: { slotsDialog.close(); root.openExport() }
                }
            }
            AppButton {
                anchors.right: parent.right; anchors.rightMargin: 20
                anchors.verticalCenter: parent.verticalCenter
                text: "Kapat"
                onClicked: slotsDialog.close()
            }
        }
        background: Rectangle { color: Theme.bgSurface; border.color: Theme.borderDefault; radius: Theme.radiusLarge }
        QQC2.Overlay.modal: Rectangle { color: "#A0050810" }
    }

    function showResult(success) {
        feedback.success = success
        feedback.message = appBridge ? appBridge.presetStatus : ""
        feedback.open()
        if (success) feedbackTimer.restart()
        else feedbackTimer.stop()
    }

    FileDialog {
        id: importDialog
        objectName: "presetImportDialog"
        parentWindow: root.Window.window
        title: qsTranslate("App", "Import Preset JSON")
        fileMode: FileDialog.OpenFile
        nameFilters: [qsTranslate("App", "JSON Presets (*.json)"), qsTranslate("App", "All Files (*.*)")]
        onAccepted: {
            if (root.appBridge && selectedFile.toString().length > 0)
                root.showResult(root.appBridge.importPreset(selectedFile.toString()))
            root.finished()
        }
        onRejected: root.finished()
    }

    FileDialog {
        id: saveDialog
        objectName: "presetSaveDialog"
        parentWindow: root.Window.window
        title: qsTranslate("App", "Export Preset JSON")
        fileMode: FileDialog.SaveFile
        defaultSuffix: "json"
        nameFilters: [qsTranslate("App", "JSON Presets (*.json)")]
        onAccepted: {
            if (root.appBridge && selectedFile.toString().length > 0)
                root.showResult(root.appBridge.exportPresetTo("", selectedFile.toString()).length > 0)
            root.finished()
        }
        onRejected: root.finished()
    }

    QQC2.Popup {
        id: feedback
        objectName: "presetFeedback"
        property string message: ""
        property bool success: true
        parent: QQC2.Overlay.overlay
        x: Math.max(8, (parent.width - width) / 2)
        y: 58
        width: Math.min(560, parent.width - 16)
        padding: 12
        z: 20001
        closePolicy: QQC2.Popup.CloseOnEscape | QQC2.Popup.CloseOnPressOutside
        background: Rectangle {
            color: Theme.bgSurface
            border.color: feedback.success ? Theme.success : Theme.danger
            radius: Theme.radiusMedium
        }
        contentItem: Row {
            spacing: 8
            Text {
                width: parent.width - dismissButton.width - parent.spacing
                anchors.verticalCenter: parent.verticalCenter
                text: feedback.message
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.family: Theme.fontFamily
                font.pixelSize: Theme.fontSizeLabel
                color: Theme.textPrimary
            }
            AppIconButton {
                id: dismissButton
                iconName: "close"
                tooltipText: qsTranslate("App", "Close")
                onClicked: feedback.close()
            }
        }
        onClosed: feedbackTimer.stop()
    }
    Timer { id: feedbackTimer; interval: 6000; onTriggered: feedback.close() }
}
