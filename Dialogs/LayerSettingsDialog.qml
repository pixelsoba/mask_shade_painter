import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15

Dialog {
    id: layerSettingsDialog
    property var backend
    property int layerIndex: -1
    property var layerData
    title: "Layer Settings"
    modal: true
    standardButtons: Dialog.Ok | Dialog.Cancel

    function openFor(index, data) {
        layerIndex = index
        layerData = data
        if (layerData) {
            blendCombo.currentIndex = blendCombo.model.indexOf(layerData.blendMode)
            opacitySlider.value = layerData.opacity
        }
        open()
    }

    onAccepted: {
        if (backend && layerIndex >= 0) {
            backend.setLayerBlendMode(layerIndex, blendCombo.model[blendCombo.currentIndex])
            backend.setLayerOpacity(layerIndex, opacitySlider.value)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 12

        RowLayout {
            spacing: 8
            Label { text: "Blend mode"; color: "#dfe2e7"; font.family: "Fira Sans" }
            ComboBox {
                id: blendCombo
                Layout.fillWidth: true
                model: ["normal", "add", "multiply", "xor"]
            }
        }

        RowLayout {
            spacing: 8
            Label { text: "Opacity"; color: "#dfe2e7"; font.family: "Fira Sans" }
            Slider {
                id: opacitySlider
                from: 0; to: 1; stepSize: 0.01
                Layout.fillWidth: true
            }
            Label {
                text: Math.round(opacitySlider.value * 100) + "%"
                width: 50
                horizontalAlignment: Text.AlignHCenter
                color: "#8ca0b3"
                font.family: "Fira Mono"
            }
        }
    }
}
