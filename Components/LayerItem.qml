import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Rectangle {
    id: root
    property var layerData
    property var backend
    property var settingsDialog
    radius: 6
    color: layerData && layerData.active ? "#313744" : "#2a2f39"
    border.color: layerData && layerData.active ? Theme.colors.layerActiveBorder : Theme.colors.layerInactiveBorder
    width: ListView.view ? ListView.view.width - 8 : 200
    height: 72

    RowLayout {
        anchors.fill: parent
        anchors.margins: 8
        spacing: Theme.spacing.xs

        ToolButton {
            id: visibilityBtn
            checkable: true
            checked: layerData ? layerData.visible : true
            icon.source: checked ? "../assets/icons/eye-visible.svg" : "../assets/icons/eye-hidden.svg"
            icon.color: Theme.colors.textPrimary
            icon.width: 22
            icon.height: 22
            flat: true
            implicitWidth: 32
            implicitHeight: 32
            opacity: checked ? 1.0 : 0.4
            onClicked: {
                if (backend && layerData) {
                    backend.setLayerVisible(layerData.index, !layerData.visible)
                }
            }
        }

        ColumnLayout {
            spacing: 4
            Label {
                Layout.fillWidth: true
                text: layerData ? layerData.name : ""
                color: Theme.colors.textPrimary
                font.family: Theme.fonts.sans
            }
            RowLayout {
                spacing: 6
                ToolButton {
                    icon.source: "../assets/icons/layer-com.svg"
                    icon.color: Theme.colors.textPrimary
                    icon.width: 22
                    icon.height: 22
                    implicitWidth: 32
                    implicitHeight: 32
                    onClicked: {
                        if (backend && layerData) {
                            if (settingsDialog) settingsDialog.openFor(layerData.index, layerData)
                        }
                    }
                }
            }
        }
    }

    MouseArea {
        anchors.fill: parent
        acceptedButtons: Qt.LeftButton
        propagateComposedEvents: true
        hoverEnabled: false
        z: -1
        onClicked: function(mouse) {
            if (backend && layerData) backend.setActiveLayer(layerData.index)
        }
    }
}
