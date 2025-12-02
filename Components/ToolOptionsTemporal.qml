import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Row {
    spacing: 8
    property var canvas

    CheckBox {
        id: tempPauseCheck
        checked: canvas ? canvas.tempPauseOnIdle : true
        text: "Pause when not moving"
        onToggled: if (canvas) canvas.tempPauseOnIdle = checked
        contentItem: Text {
            text: tempPauseCheck.text
            font: tempPauseCheck.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: tempPauseCheck.indicator.width + tempPauseCheck.spacing
        }
    }
    Connections {
        target: canvas ? canvas : null
        function onTempPauseOnIdleChanged() {
            tempPauseCheck.checked = canvas ? canvas.tempPauseOnIdle : true
        }
    }

    Label { text: "Start"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: tempStartSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.tempSampleStart)
        value: canvas ? Math.round(canvas.tempStart * 100) : 0
        onValueModified: if (canvas) canvas.tempStart = value / 100.0
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    CheckBox {
        id: tempSampleStart
        text: "Pick start"
        checked: canvas ? canvas.tempSampleStart : false
        onToggled: if (canvas) canvas.tempSampleStart = checked
        contentItem: Text {
            text: tempSampleStart.text
            font: tempSampleStart.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: tempSampleStart.indicator.width + tempSampleStart.spacing
        }
    }

    Label { text: "End"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: tempEndSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.tempSampleEnd)
        value: canvas ? Math.round(canvas.tempEnd * 100) : 0
        onValueModified: if (canvas) canvas.tempEnd = value / 100.0
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    CheckBox {
        id: tempSampleEnd
        text: "Pick end"
        checked: canvas ? canvas.tempSampleEnd : false
        onToggled: if (canvas) canvas.tempSampleEnd = checked
        contentItem: Text {
            text: tempSampleEnd.text
            font: tempSampleEnd.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: tempSampleEnd.indicator.width + tempSampleEnd.spacing
        }
    }
}
