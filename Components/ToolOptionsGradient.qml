import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import "../Theme.js" as Theme

Row {
    spacing: 8
    property var canvas

    Label { text: "Gradient type"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    ComboBox {
        id: gradientTypeCombo
        model: ["Linear", "Radial"]
        currentIndex: canvas ? (canvas.toolMode === "linearGradient" ? 0 : 1) : 0
        onActivated: function(idx) {
            if (!canvas) return;
            canvas.toolMode = idx === 0 ? "linearGradient" : "radialGradient";
        }
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    Label { text: "Start"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: gradStartSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.gradientSampleStart)
        value: canvas ? Math.round(canvas.gradientStart * 100) : 0
        onValueModified: if (canvas) canvas.gradientStart = value / 100.0
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    CheckBox {
        id: gradSampleStart
        text: "Pick start"
        checked: canvas ? canvas.gradientSampleStart : false
        onToggled: if (canvas) canvas.gradientSampleStart = checked
        contentItem: Text {
            text: gradSampleStart.text
            font: gradSampleStart.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: gradSampleStart.indicator.width + gradSampleStart.spacing
        }
    }
    Label { text: "End"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: gradEndSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.gradientSampleEnd)
        value: canvas ? Math.round(canvas.gradientEnd * 100) : 100
        onValueModified: if (canvas) canvas.gradientEnd = value / 100.0
        palette.text: Theme.colors.textOnLight
        palette.buttonText: Theme.colors.textOnLight
    }
    CheckBox {
        id: gradSampleEnd
        text: "Pick end"
        checked: canvas ? canvas.gradientSampleEnd : false
        onToggled: if (canvas) canvas.gradientSampleEnd = checked
        contentItem: Text {
            text: gradSampleEnd.text
            font: gradSampleEnd.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: gradSampleEnd.indicator.width + gradSampleEnd.spacing
        }
    }
    CheckBox {
        id: gradClampCheck
        text: "Clamp"
        checked: canvas ? canvas.gradientClamp : true
        onToggled: if (canvas) canvas.gradientClamp = checked
        contentItem: Text {
            text: gradClampCheck.text
            font: gradClampCheck.font
            color: Theme.colors.textPrimary
            verticalAlignment: Text.AlignVCenter
            leftPadding: gradClampCheck.indicator.width + gradClampCheck.spacing
        }
    }
}
