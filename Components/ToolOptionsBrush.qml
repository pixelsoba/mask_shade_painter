import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

    Row {
    spacing: 6
    property var canvas

    Label { text: "Brush size"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: brushSizeSpin
        from: 1; to: 512; stepSize: 1
        editable: true
        value: canvas ? canvas.brushSize : 0
        onValueModified: if (canvas) canvas.brushSize = value
        palette.text: Theme.colors.textPrimary
        palette.buttonText: Theme.colors.textPrimary
    }

    Label { text: "Gray"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: graySpin
        from: 0; to: 255; stepSize: 1
        editable: true
        value: canvas ? canvas.grayValue : 0
        onValueModified: if (canvas) canvas.grayValue = value
        palette.text: Theme.colors.textPrimary
        palette.buttonText: Theme.colors.textPrimary
    }
}
