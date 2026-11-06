import QtQuick
import QtQuick.Layouts
import QtQuick.Controls as QQC2
import ".."
import "../controls"

Rectangle {
    id: root
    color: Theme.bgSurface
    implicitHeight: modelsColumn.implicitHeight + 24
    property var appBridge: null
    readonly property var manager: appBridge ? appBridge.models : null
    property string removeModelId: ""
    property string removeModelName: ""

    function confirmRemoval(id, name) {
        removeModelId = id
        removeModelName = name
        removeDialog.open()
    }
    onVisibleChanged: if (!visible) removeDialog.close()

    Flickable {
        id: modelsViewport
        objectName: "modelsViewport"
        anchors.fill: parent; anchors.margins: 12
        contentWidth: width
        contentHeight: Math.max(height, modelsColumn.implicitHeight)
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Column {
            id: modelsColumn
            objectName: "modelsColumn"
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            y: 0
            spacing: 20
            Text {
                width: parent.width
                text: "Modeller programla birlikte çevrimdışı kullanılır. "Bulunamadı" görünen model bu bilgisayarda yüklü değildir."
                color: Theme.textSecondary
                font.family: Theme.fontFamily
                font.pixelSize: 12
                wrapMode: Text.WordWrap
            }
            Column {
                width: parent.width
                spacing: 14
                Repeater {
                    model: ["Upscale", "ReShade"]
                    delegate: Column {
                        id: categoryBox
                        required property string modelData
                        objectName: "models-category-" + modelData
                        width: parent.width
                        spacing: 12
                        Text {text:categoryBox.modelData==="Upscale"?qsTranslate("App","Upscale"):"ReShade";color:Theme.textPrimary;font.family:Theme.fontFamily;font.pixelSize:Theme.fontSizeSubtitle;font.weight:Font.DemiBold}
                        Rectangle {width:parent.width;height:1;color:Theme.borderSubtle}
                        Column {
                            id: categoryColumn
                            width: parent.width
                            Column {
                                width: parent.width
                                spacing: 16
                                Repeater {
                                    model: root.manager
                                    delegate: Item {
                                        id: modelRow
                                        required property string modelId
                                        required property string modelName
                                        required property string modelCategory
                                        required property string sizeGb
                                        required property bool isInstalled
                                        required property bool isActive
                                        required property bool queued
                                        required property bool partial
                                        required property bool inUse
                                        required property string error
                                        required property double fraction
                                        required property double received
                                        required property double speed
                                        required property string modelState
                                        readonly property bool busy: isActive || queued
                                        readonly property bool showProgress: busy || partial
                                        objectName: "model-row-" + modelId
                                        visible: modelCategory === categoryBox.modelData
                                        width: parent.width
                                        implicitHeight: rowColumn.implicitHeight
                                        Column {
                                            id: rowColumn
                                            width: parent.width
                                            spacing: 10
                                            RowLayout {
                                                width: parent.width
                                                spacing: 12
                                                Text {
                                                    objectName: "model-name-" + modelRow.modelId
                                                    text: modelRow.modelName
                                                    color: Theme.textPrimary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 14
                                                    font.weight: Font.Medium
                                                    elide: Text.ElideRight
                                                    Layout.fillWidth: true
                                                }
                                                Text {
                                                    objectName: "model-size-" + modelRow.modelId
                                                    visible: !modelRow.busy && (modelRow.isInstalled || modelRow.partial)
                                                    text: modelRow.sizeGb + " GB"
                                                    color: Theme.textSecondary
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 13
                                                }
                                                Text {
                                                    objectName: "model-status-" + modelRow.modelId
                                                    text: modelRow.isInstalled ? "\u2713 Yüklü" : "Bulunamadı"
                                                    color: modelRow.isInstalled ? Theme.success : Theme.warning
                                                    font.family: Theme.fontFamily
                                                    font.pixelSize: 13
                                                    font.weight: Font.DemiBold
                                                    Layout.minimumWidth: 92
                                                    horizontalAlignment: Text.AlignRight
                                                }
                                            }
                                            Text {
                                                visible: modelRow.error.length > 0
                                                objectName: "model-error-" + modelRow.modelId
                                                width: parent.width
                                                text: modelRow.error
                                                color: Theme.danger
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                wrapMode: Text.WordWrap
                                            }
                                            Rectangle {
                                                visible: false
                                                width: parent.width
                                                height: 4
                                                radius: 2
                                                color: Theme.bgInput
                                                Rectangle { width: parent.width * Math.max(0, Math.min(1, modelRow.fraction)); height: parent.height; radius: 2; color: modelRow.busy ? Theme.accent : Theme.textSecondary }
                                            }
                                            Text {
                                                objectName: "model-transfer-status-" + modelRow.modelId
                                                visible: false
                                                width: parent.width
                                                text: modelRow.busy && (modelRow.modelState === "Downloading" || modelRow.modelState === "")
                                                      ? qsTranslate("App", "%1% · %2 / %3 GB · %4 MB/s").arg(Math.floor(modelRow.fraction * 100)).arg((modelRow.received / 1e9).toLocaleString(Qt.locale(), 'f', 2)).arg(modelRow.sizeGb).arg((modelRow.speed / 1e6).toLocaleString(Qt.locale(), 'f', 1))
                                                      : qsTranslate("App", "%1% · %2 / %3 GB").arg(Math.floor(modelRow.fraction * 100)).arg((modelRow.received / 1e9).toLocaleString(Qt.locale(), 'f', 2)).arg(modelRow.sizeGb)
                                                        + (modelRow.busy ? " · " + qsTranslate("App", modelRow.modelState) : "")
                                                color: Theme.textSecondary
                                                font.family: Theme.fontFamily
                                                font.pixelSize: 12
                                                wrapMode: Text.WordWrap
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    QQC2.Dialog {
        id: removeDialog
        objectName: "model-remove-confirmation"
        parent: QQC2.Overlay.overlay
        anchors.centerIn: parent
        width: Math.min(420, parent.width - 40)
        modal: true
        focus: true
        dim: true
        closePolicy: QQC2.Popup.CloseOnEscape
        padding: 20
        spacing: 12
        header: QQC2.Label {
            text: qsTranslate("App", "Remove %1?").arg(root.removeModelName)
            color: Theme.textPrimary
            font.family: Theme.fontFamily
            font.pixelSize: 18
            font.weight: Font.DemiBold
            padding: 20
            bottomPadding: 0
        }
        contentItem: Text {
            text: qsTranslate("App", "Are you sure? You can download it again later.")
            color: Theme.textSecondary
            font.family: Theme.fontFamily
            font.pixelSize: 13
            wrapMode: Text.WordWrap
        }
        footer: Item {
            implicitHeight: 52
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 20
                spacing: 8
                AppButton {
                    id: keepModelButton
                    objectName: "model-remove-reject"
                    text: qsTranslate("App", "Cancel")
                    onClicked: removeDialog.reject()
                }
                AppButton {
                    objectName: "model-remove-approve"
                    text: qsTranslate("App", "Remove")
                    variant: "danger"
                    onClicked: removeDialog.accept()
                }
            }
        }
        background: Rectangle { color: Theme.bgSurface; border.color: Theme.borderDefault; radius: 10 }
        QQC2.Overlay.modal: Rectangle { color: "#80000000" }
        onOpened: keepModelButton.forceActiveFocus()
        onAccepted: if (root.manager && root.removeModelId.length) root.manager.remove(root.removeModelId)
    }
}
