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
        palette.text: Theme.colors.textPrimary
        palette.buttonText: Theme.colors.textPrimary
    }
    Label { text: "Start"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: gradStartSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.gradientSampleStart)
        value: canvas ? Math.round(canvas.gradientStart * 100) : 0
        onValueModified: if (canvas) canvas.gradientStart = value / 100.0
        palette.text: Theme.colors.textPrimary
        palette.buttonText: Theme.colors.textPrimary
    }
    CheckBox {
        id: gradSampleStart
        text: "Pick start"
        checked: canvas ? canvas.gradientSampleStart : false
        onToggled: if (canvas) canvas.gradientSampleStart = checked
        palette.text: Theme.colors.textPrimary
    }
    Label { text: "End"; font.family: Theme.fonts.sans; color: Theme.colors.textPrimary }
    SpinBox {
        id: gradEndSpin
        from: 0; to: 100; stepSize: 1
        editable: true
        enabled: !(canvas && canvas.gradientSampleEnd)
        value: canvas ? Math.round(canvas.gradientEnd * 100) : 100
        onValueModified: if (canvas) canvas.gradientEnd = value / 100.0
        palette.text: Theme.colors.textPrimary
        palette.buttonText: Theme.colors.textPrimary
    }
    CheckBox {
        id: gradSampleEnd
        text: "Pick end"
        checked: canvas ? canvas.gradientSampleEnd : false
        onToggled: if (canvas) canvas.gradientSampleEnd = checked
        palette.text: Theme.colors.textPrimary
    }
    CheckBox {
        id: gradClampCheck
        text: "Clamp"
        checked: canvas ? canvas.gradientClamp : true
        onToggled: if (canvas) canvas.gradientClamp = checked
        palette.text: Theme.colors.textPrimary
    }
}
