import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: resizeDialog
    property var backend
    property bool createNew: false
    signal canvasApplied(bool wasNew)
    title: "Resize Canvas"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    onOpened: {
        if (backend) {
            widthSpin.value = backend.canvasWidth
            heightSpin.value = backend.canvasHeight
        }
    }
    onAccepted: {
        var wasNew = createNew
        if (backend) {
            if (createNew) {
                backend.newCanvas(widthSpin.value, heightSpin.value)
            } else {
                backend.resizeCanvas(widthSpin.value, heightSpin.value, anchorCombo.currentText)
            }
        }
        createNew = false
        canvasApplied(wasNew)
    }
    onRejected: {
        createNew = false
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            spacing: 8
            Label { text: "Width"; color: "#dfe2e7"; font.family: "Fira Sans" }
            SpinBox {
                id: widthSpin
                from: 16; to: 8192; stepSize: 8
                Layout.fillWidth: true
                editable: true
            }
        }

        RowLayout {
            spacing: 8
            Label { text: "Height"; color: "#dfe2e7"; font.family: "Fira Sans" }
            SpinBox {
                id: heightSpin
                from: 16; to: 8192; stepSize: 8
                Layout.fillWidth: true
                editable: true
            }
        }

        RowLayout {
            spacing: 8
            Label { text: "Anchor"; color: "#dfe2e7"; font.family: "Fira Sans" }
            ComboBox {
                id: anchorCombo
                Layout.fillWidth: true
                model: ["center", "topLeft", "topRight", "bottomLeft", "bottomRight"]
                currentIndex: 0
            }
        }
    }
}
