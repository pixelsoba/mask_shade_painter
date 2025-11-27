import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: extendDialog
    property var backend
    title: "Extend Canvas"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel
    onOpened: {
        if (backend) {
            addWidthSpin.value = 0
            addHeightSpin.value = 0
        }
    }
    onAccepted: {
        if (backend) {
            const newW = Math.max(1, backend.canvasWidth + addWidthSpin.value)
            const newH = Math.max(1, backend.canvasHeight + addHeightSpin.value)
            backend.resizeCanvas(newW, newH, anchorCombo.currentText)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            spacing: 8
            Label { text: "Add Width"; color: "#dfe2e7"; font.family: "Fira Sans" }
            SpinBox {
                id: addWidthSpin
                from: -4096; to: 4096; stepSize: 8
                Layout.fillWidth: true
                editable: true
            }
        }

        RowLayout {
            spacing: 8
            Label { text: "Add Height"; color: "#dfe2e7"; font.family: "Fira Sans" }
            SpinBox {
                id: addHeightSpin
                from: -4096; to: 4096; stepSize: 8
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
