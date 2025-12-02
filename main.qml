import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQml 2.15
import Qt.labs.platform 1.1 as Platform
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
    title: "MaskShadePainter - MVP" + (projectPath ? " - " + projectPath : "") + ((canvas && canvas.modified) ? " *" : "")

    property alias canvas: viewport.canvas
    property bool temporalActive: canvas && canvas.toolMode === "temporal"
    property string projectPath: ""
    property var pendingAction: null
    readonly property bool hasUnsavedChanges: canvas && canvas.modified

    function requireConfirmation(action) {
        if (hasUnsavedChanges) {
            pendingAction = action
            unsavedDialog.open()
        } else {
            action()
        }
    }

    function triggerNewCanvas() {
        requireConfirmation(function() {
            resizeDialog.createNew = true
            resizeDialog.open()
        })
    }

    function triggerOpen() { requireConfirmation(function() { openDialog.open() }) }
    function triggerQuit() { requireConfirmation(function() { Qt.quit() }) }
    function triggerImportLayer() { importDialog.open() }
    function triggerExportPng() { exportDialog.open() }

    function triggerSaveAs() { saveDialog.open() }

    function triggerSave() {
        if (!canvas)
            return
        if (!projectPath) {
            triggerSaveAs()
            return
        }
        canvas.saveProject(projectPath)
    }

    function normalizePath(input) {
        if (!input)
            return ""
        var s = input.toString ? input.toString() : input
        if (s.startsWith("file:///")) {
            s = decodeURIComponent(s.replace("file:///", ""))
        }
        return s
    }

    menuBar: MenuBar {
        Menu {
            title: "File"
            MenuItem { text: "New"; onTriggered: triggerNewCanvas() }
            MenuItem { text: "Open..."; onTriggered: triggerOpen() }
            MenuItem { text: "Import as calque..."; onTriggered: triggerImportLayer() }
            MenuItem { text: "Export PNG..."; onTriggered: triggerExportPng() }
            MenuSeparator { }
            MenuItem {
                text: "Save"
                enabled: canvas && projectPath !== "" && canvas.modified
                onTriggered: triggerSave()
            }
            MenuItem { text: "Save As..."; onTriggered: triggerSaveAs() }
            MenuSeparator { }
            MenuItem { text: "Quit"; onTriggered: triggerQuit() }
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
            Components.ToolOptionsBrush { canvas: window.canvas }
        }

        Component {
            id: temporalOptions
            Components.ToolOptionsTemporal { canvas: window.canvas }
        }

        Component {
            id: fillOptions
            Components.ToolOptionsFill { canvas: window.canvas }
        }

        Component {
            id: gradientOptions
            Components.ToolOptionsGradient { canvas: window.canvas }
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

    Dialog {
        id: unsavedDialog
        title: "Modifications non enregistrees"
        modal: true
        width: 420
        standardButtons: Dialog.Yes | Dialog.No
        padding: 16
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        contentItem: ColumnLayout {
            spacing: 12
            Label {
                text: "Le travail en cours sera perdu. Continuer ?"
                wrapMode: Text.WordWrap
                color: Theme.colors.textOnLight
                font.family: Theme.fonts.sans
                Layout.fillWidth: true
            }
        }
        onAccepted: {
            if (pendingAction) pendingAction()
            pendingAction = null
        }
        onRejected: pendingAction = null
    }

    Dialog {
        id: saveDialog
        title: "Save Project As"
        modal: true
        width: 480
        standardButtons: Dialog.Ok | Dialog.Cancel
        padding: 16
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        property alias pathText: savePathField.text
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                text: "Chemin du fichier (.pms/.projectMaskShade)"
                color: Theme.colors.textOnLight
                font.family: Theme.fonts.sans
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: savePathField
                    Layout.fillWidth: true
                    color: Theme.colors.textOnLight
                    placeholderText: "ex: C:/Users/you/project.pms"
                }
                Button {
                    text: "Parcourir..."
                    onClicked: {
                        savePicker.folder = projectPath ? normalizePath(projectPath) : ""
                        savePicker.open()
                    }
                }
            }
        }
        onOpened: {
            savePathField.text = projectPath || ""
            savePathField.forceActiveFocus()
            savePathField.selectAll()
        }
        onAccepted: {
            var path = savePathField.text.trim()
            if (!path)
                return
            var lower = path.toLowerCase()
            if (!(lower.endsWith(".pms") || lower.endsWith(".projectmaskshade")))
                path = path + ".pms"
            if (canvas && canvas.saveProject(path)) {
                projectPath = path
            }
        }
    }

    Platform.FileDialog {
        id: savePicker
        title: "Enregistrer sous"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["MaskShade Project (*.pms *.projectMaskShade)", "All files (*)"]
        onAccepted: {
            var path = normalizePath(file)
            if (!path)
                return
            var lower = path.toLowerCase()
            if (!(lower.endsWith(".pms") || lower.endsWith(".projectmaskshade")))
                path = path + ".pms"
            savePathField.text = path
            if (canvas && canvas.saveProject(path)) {
                projectPath = path
                saveDialog.close()
            }
        }
    }

    Dialog {
        id: openDialog
        title: "Open Project"
        modal: true
        width: 480
        standardButtons: Dialog.Ok | Dialog.Cancel
        padding: 16
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        property alias pathText: openPathField.text
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                text: "Chemin du projet (.pms/.projectMaskShade)"
                color: Theme.colors.textOnLight
                font.family: Theme.fonts.sans
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: openPathField
                    Layout.fillWidth: true
                    color: Theme.colors.textOnLight
                    placeholderText: "ex: C:/Users/you/project.pms"
                }
                Button {
                    text: "Parcourir..."
                    onClicked: openPicker.open()
                }
            }
        }
        onOpened: {
            openPathField.forceActiveFocus()
            openPathField.selectAll()
        }
        onAccepted: {
            var path = openPathField.text.trim()
            if (canvas && path && canvas.loadProject(path)) {
                projectPath = path
            }
        }
    }

    Platform.FileDialog {
        id: openPicker
        title: "Ouvrir un projet"
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["MaskShade Project (*.pms *.projectMaskShade)", "All files (*)"]
        onAccepted: {
            var path = normalizePath(file)
            if (canvas && path && canvas.loadProject(path)) {
                projectPath = path
                openDialog.close()
            }
        }
    }

    Dialog {
        id: importDialog
        title: "Import image as calque"
        modal: true
        width: 480
        standardButtons: Dialog.Ok | Dialog.Cancel
        padding: 16
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        property alias pathText: importPathField.text
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                text: "Chemin de l'image (png/jpg/bmp)"
                color: Theme.colors.textOnLight
                font.family: Theme.fonts.sans
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: importPathField
                    Layout.fillWidth: true
                    color: Theme.colors.textOnLight
                    placeholderText: "ex: C:/Users/you/image.png"
                }
                Button {
                    text: "Parcourir..."
                    onClicked: importPicker.open()
                }
            }
        }
        onOpened: {
            importPathField.forceActiveFocus()
            importPathField.selectAll()
        }
        onAccepted: {
            var path = importPathField.text.trim()
            if (canvas && path) {
                canvas.importImageAsLayer(path)
            }
        }
    }

    Platform.FileDialog {
        id: importPicker
        title: "Importer une image"
        fileMode: Platform.FileDialog.OpenFile
        nameFilters: ["Images (*.png *.jpg *.jpeg *.bmp)", "All files (*)"]
        onAccepted: {
            var path = normalizePath(file)
            if (canvas && path) {
                importPathField.text = path
                canvas.importImageAsLayer(path)
                importDialog.close()
            }
        }
    }

    Dialog {
        id: exportDialog
        title: "Export Flattened PNG"
        modal: true
        width: 480
        standardButtons: Dialog.Ok | Dialog.Cancel
        padding: 16
        x: (window.width - width) / 2
        y: (window.height - height) / 2
        property alias pathText: exportPathField.text
        contentItem: ColumnLayout {
            spacing: 10
            Label {
                text: "Chemin du PNG exporte"
                color: Theme.colors.textOnLight
                font.family: Theme.fonts.sans
            }
            RowLayout {
                Layout.fillWidth: true
                spacing: 8
                TextField {
                    id: exportPathField
                    Layout.fillWidth: true
                    color: Theme.colors.textOnLight
                    placeholderText: "ex: C:/Users/you/export.png"
                }
                Button {
                    text: "Parcourir..."
                    onClicked: exportPicker.open()
                }
            }
        }
        onOpened: {
            exportPathField.forceActiveFocus()
            exportPathField.selectAll()
        }
        onAccepted: {
            var path = exportPathField.text.trim()
            if (!path)
                return
            if (!path.toLowerCase().endsWith(".png"))
                path = path + ".png"
            if (canvas)
                canvas.exportPng(path)
        }
    }

    Connections {
        target: resizeDialog
        function onCanvasApplied(wasNew) {
            if (wasNew) {
                projectPath = ""
            }
        }
    }

    Platform.FileDialog {
        id: exportPicker
        title: "Exporter en PNG"
        fileMode: Platform.FileDialog.SaveFile
        nameFilters: ["PNG image (*.png)", "All files (*)"]
        onAccepted: {
            var path = normalizePath(file)
            if (!path)
                return
            if (!path.toLowerCase().endsWith(".png"))
                path = path + ".png"
            exportPathField.text = path
            if (canvas)
                canvas.exportPng(path)
            exportDialog.close()
        }
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
