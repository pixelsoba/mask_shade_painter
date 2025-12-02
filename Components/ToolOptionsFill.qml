import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Row {
    spacing: 8
    property var canvas

    Label { text: "Tolerance"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: fillToleranceSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        value: canvas ? canvas.fillTolerance : 0
        onValueModified: if (canvas) canvas.fillTolerance = value
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    CheckBox {
        id: fillSampleCheck
        text: "Sample all layers"
        checked: canvas ? canvas.fillSampleAllLayers : false
        onToggled: if (canvas) canvas.fillSampleAllLayers = checked
        contentItem: Text {
            text: fillSampleCheck.text
            font: fillSampleCheck.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: fillSampleCheck.indicator.width + fillSampleCheck.spacing
        }
    }
    CheckBox {
        id: fillContiguousCheck
        text: "Contiguous only"
        checked: canvas ? canvas.fillContiguous : true
        onToggled: if (canvas) canvas.fillContiguous = checked
        contentItem: Text {
            text: fillContiguousCheck.text
            font: fillContiguousCheck.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: fillContiguousCheck.indicator.width + fillContiguousCheck.spacing
        }
    }
}
