import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml 2.15
import MSP 1.0
import "Dialogs" as Dialogs
import "Components" as Components
import "Theme.js" as Theme

ApplicationWindow {
    id: window
    width: 1200
    height: 820
    visible: true
    color: "#171819"
    title: "MaskShadePainter - MVP"

    property alias canvas: viewport.canvas
    property bool temporalActive: canvas && canvas.toolMode === "temporal"

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text: "New"; onTriggered: console.log("TODO new canvas") }
            MenuItem { text: "Open..."; onTriggered: console.log("TODO open") }
            MenuItem { text: "Import..."; onTriggered: console.log("TODO import") }
            MenuItem { text: "Export PNG..."; onTriggered: console.log("TODO export") }
            MenuSeparator { }
            MenuItem { text: "Save As..."; onTriggered: console.log("TODO save as") }
            MenuSeparator { }
            MenuItem { text: "Quit"; onTriggered: Qt.quit() }
        }
        Menu {
            title: "Edit"
            MenuItem {
                text: "Undo"
                enabled: canvas ? canvas.undoAvailable : false
                onTriggered: if (canvas) canvas.undo()
            }
            MenuItem {
                text: "Redo"
                enabled: canvas ? canvas.redoAvailable : false
                onTriggered: if (canvas) canvas.redo()
            }
            MenuSeparator { }
            MenuItem { text: "Copy"; onTriggered: console.log("TODO copy") }
            MenuItem { text: "Paste"; onTriggered: console.log("TODO paste") }
        }
        Menu {
            title: "Canvas"
            MenuItem { text: "Resize Canvas..."; onTriggered: resizeDialog.open() }
            MenuItem { text: "Change Size with Extension..."; onTriggered: extendDialog.open() }
        }
        Menu {
            title: "Layers"
            MenuItem { text: "New Layer"; onTriggered: console.log("TODO layer add") }
            MenuItem { text: "Duplicate Layer"; onTriggered: console.log("TODO layer duplicate") }
            MenuItem { text: "Delete Layer"; onTriggered: console.log("TODO layer delete") }
            MenuSeparator { }
            MenuItem { text: "Merge Down"; onTriggered: console.log("TODO layer merge") }
            MenuItem { text: "Histogram Adjust..."; onTriggered: console.log("TODO histogram adjust") }
        }
        Menu {
            title: "Help"
            MenuItem { text: "About"; onTriggered: console.log("MaskShadePainter MVP") }
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 12
        anchors.margins: 16

        Loader {
            id: toolbarLoader
            Layout.fillWidth: true
            sourceComponent: mainToolBar
        }

        Rectangle {
            id: toolSettings
            Layout.fillWidth: true
            height: 80
            radius: 8
            color: Theme.colors.panel
            border.color: Theme.colors.panelBorder
            border.width: 1

            Flow {
                id: flowContent
                anchors.fill: parent
                anchors.margins: 14
                spacing: 12

                Loader {
                    sourceComponent: brushOptions
                    active: !!canvas
                }
                Loader {
                    sourceComponent: temporalOptions
                    active: canvas && window.temporalActive
                }
                Loader {
                    sourceComponent: fillOptions
                    active: canvas && canvas.toolMode === "fill"
                }
                Loader {
                    sourceComponent: gradientOptions
                    active: canvas && (canvas.toolMode === "linearGradient" || canvas.toolMode === "radialGradient")
                }
            }
        }

        Component {
            id: brushOptions
            Components.ToolOptionsBrush { canvas: canvas }
        }

        Component {
            id: temporalOptions
            Components.ToolOptionsTemporal { canvas: canvas }
        }

        Component {
            id: fillOptions
            Components.ToolOptionsFill { canvas: canvas }
        }

        Component {
            id: gradientOptions
            Components.ToolOptionsGradient { canvas: canvas }
        }

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 12

        Rectangle {
            id: viewportFrame
            Layout.fillWidth: true
            Layout.fillHeight: true
            radius: 12
            color: "#202328"
            border.color: "#2e333b"
            border.width: 1
            clip: true

            Components.CanvasViewport {
                id: viewport
                anchors.fill: parent
            }
        }

            Rectangle {
                id: layersPanel
                Layout.preferredWidth: 260
                Layout.fillHeight: true
                radius: 10
                color: "#1e2127"
                border.color: "#2f343d"
                border.width: 1

                ColumnLayout {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    Label {
                        text: "Layers"
                        font.family: Theme.fonts.sans
                        color: Theme.colors.textPrimary
                    }
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 6
                        Components.LayerActions { backend: canvas }
                    }
                    Rectangle {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        radius: 6
                        color: "#262a32"
                        border.color: "#323844"
                        ListView {
                            id: layerList
                            anchors.fill: parent
                            anchors.margins: 6
                            clip: true
                            spacing: 6
                            model: canvas ? canvas.layersModel : []
                            delegate: Components.LayerItem {
                                layerData: modelData
                                backend: canvas
                                settingsDialog: layerSettingsDialog
                            }
                        }
                    }
                }
            }
        }
    }

    Dialogs.CanvasResizeDialog {
        id: resizeDialog
        backend: canvas
        x: (window.width - width) / 2
        y: (window.height - height) / 2
    }

    Dialogs.CanvasExtendDialog {
        id: extendDialog
        backend: canvas
        x: (window.width - width) / 2
        y: (window.height - height) / 2
    }

    Dialogs.LayerSettingsDialog {
        id: layerSettingsDialog
        backend: canvas
        x: (window.width - width) / 2
        y: (window.height - height) / 2
    }

    Component {
        id: mainToolBar
        ToolBar {
            contentHeight: 40
            background: Rectangle {
                color: Theme.colors.panel
                border.color: Theme.colors.panelBorder
                radius: 6
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 8
                spacing: 6
                ButtonGroup { id: toolButtonsGroup }

                Row {
                    spacing: 6
                    ToolButton {
                        icon.source: "assets/icons/brush.svg"
                        icon.color: Theme.colors.textPrimary
                        ToolTip.visible: hovered
                        ToolTip.text: "Brush"
                        checkable: true
                        checked: canvas && canvas.toolMode === "brush"
                        ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "brush"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                }
                ToolButton {
                    icon.source: "assets/icons/eraser.svg"
                    icon.color: Theme.colors.textPrimary
                    ToolTip.visible: hovered
                    ToolTip.text: "Eraser"
                    checkable: true
                    checked: canvas && canvas.toolMode === "eraser"
                    ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "eraser"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                }
                ToolButton {
                    icon.source: "assets/icons/temporal.svg"
                    icon.color: Theme.colors.textPrimary
                    ToolTip.visible: hovered
                    ToolTip.text: "Temporal Pen"
                    checkable: true
                    checked: canvas && canvas.toolMode === "temporal"
                    ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "temporal"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                }
                ToolButton {
                    icon.source: "assets/icons/bucket.svg"
                    icon.color: Theme.colors.textPrimary
                    ToolTip.visible: hovered
                    ToolTip.text: "Fill"
                    checkable: true
                    checked: canvas && canvas.toolMode === "fill"
                    ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "fill"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                }
                ToolButton {
                    icon.source: "assets/icons/gradient.svg"
                    icon.color: Theme.colors.textPrimary
                    ToolTip.visible: hovered
                    ToolTip.text: "Gradient"
                    checkable: true
                    checked: canvas && (canvas.toolMode === "linearGradient" || canvas.toolMode === "radialGradient")
                    ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "linearGradient"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                }
                ToolButton {
                    icon.source: "assets/icons/color-picker.svg"
                    icon.color: Theme.colors.textPrimary
                    ToolTip.visible: hovered
                    ToolTip.text: "Picker"
                    checkable: true
                    checked: canvas && canvas.toolMode === "picker"
                    ButtonGroup.group: toolButtonsGroup
                        onClicked: if (canvas) canvas.toolMode = "picker"
                        background: Rectangle {
                            color: parent.checked ? "#2f343d" : "transparent"
                            border.color: parent.checked ? Theme.colors.layerActiveBorder : "transparent"
                            radius: 4
                        }
                    }
                }
                Item { Layout.fillWidth: true }
            }
        }
    }
}
