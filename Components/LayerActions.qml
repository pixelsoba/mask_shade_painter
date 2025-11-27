import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

RowLayout {
    property var backend
    spacing: Theme.spacing.xs
    property int iconSize: 24
    property int buttonSize: 32

    ToolButton {
        icon.source: "../assets/icons/layer-add.svg"
        icon.width: iconSize
        icon.height: iconSize
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        onClicked: if (backend) backend.addLayer()
    }
    ToolButton {
        icon.source: "../assets/icons/layer-duplicate.svg"
        icon.width: iconSize
        icon.height: iconSize
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        onClicked: if (backend) backend.duplicateActiveLayer()
    }
    ToolButton {
        icon.source: "../assets/icons/layer-delete.svg"
        icon.width: iconSize
        icon.height: iconSize
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        enabled: backend ? backend.layersModel.length > 1 : false
        onClicked: if (backend) backend.deleteActiveLayer()
    }
    ToolButton {
        icon.source: "../assets/icons/layer-up.svg"
        icon.width: iconSize
        icon.height: iconSize
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        onClicked: if (backend) backend.moveLayerUp(backend.activeLayerIndex)
    }
    ToolButton {
        icon.source: "../assets/icons/layer-down.svg"
        icon.width: iconSize
        icon.height: iconSize
        implicitWidth: buttonSize
        implicitHeight: buttonSize
        onClicked: if (backend) backend.moveLayerDown(backend.activeLayerIndex)
    }
}
