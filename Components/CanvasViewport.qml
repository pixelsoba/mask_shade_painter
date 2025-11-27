import QtQuick 2.15
import QtQuick.Controls 2.15
import MSP 1.0

Item {
    id: root
    property real viewportScale: 1.0
    property real viewportOffsetX: 0
    property real viewportOffsetY: 0
    property alias canvas: canvas

    function resetView() {
        if (!canvas) return;
        viewportScale = 1.0
        viewportOffsetX = (width - canvas.canvasWidth * viewportScale) / 2
        viewportOffsetY = (height - canvas.canvasHeight * viewportScale) / 2
    }

    Component.onCompleted: resetView()

    Connections {
        target: canvas
        function onCanvasSizeChanged() { root.resetView() }
    }

    Item {
        id: canvasContainer
        width: canvas ? canvas.canvasWidth : 0
        height: canvas ? canvas.canvasHeight : 0
        x: viewportOffsetX
        y: viewportOffsetY
        scale: viewportScale
        transformOrigin: Item.TopLeft

        Rectangle {
            id: canvasFrame
            anchors.fill: parent
            radius: 4
            border.color: "#3a3f4a"
            color: "transparent"
        }

        Image {
            id: checker
            anchors.fill: parent
            source: "../assets/textures/checkerboard_tile.png"
            fillMode: Image.Tile
            horizontalAlignment: Image.AlignLeft
            verticalAlignment: Image.AlignTop
        }

        PainterBackend {
            id: canvas
            anchors.fill: parent
            toolMode: "brush"
            brushSize: 20
            grayValue: 255
            tempStart: 0.0
            tempEnd: 1.0
            tempPauseOnIdle: true
        }
    }

    MouseArea {
        id: viewMouseArea
        anchors.fill: parent
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
        property bool panning: false
        property real lastX: 0
        property real lastY: 0

        onPressed: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                panning = true
                lastX = mouse.x
                lastY = mouse.y
            } else if (mouse.button === Qt.LeftButton) {
                var pt = canvas.mapFromItem(viewMouseArea, mouse.x, mouse.y)
                canvas.inputPressed(pt.x, pt.y)
            }
        }
        onPositionChanged: function(mouse) {
            if (panning) {
                var dx = mouse.x - lastX
                var dy = mouse.y - lastY
                viewportOffsetX += dx
                viewportOffsetY += dy
                lastX = mouse.x
                lastY = mouse.y
            } else if (mouse.buttons & Qt.LeftButton) {
                var pt = canvas.mapFromItem(viewMouseArea, mouse.x, mouse.y)
                canvas.inputMoved(pt.x, pt.y)
            }
        }
        onReleased: function(mouse) {
            if (mouse.button === Qt.MiddleButton) {
                panning = false
            } else if (mouse.button === Qt.LeftButton) {
                var pt = canvas.mapFromItem(viewMouseArea, mouse.x, mouse.y)
                canvas.inputReleased(pt.x, pt.y)
            }
        }
        onWheel: function(wheel) {
            if (wheel.modifiers & Qt.ControlModifier) {
                var oldScale = viewportScale
                var factor = wheel.angleDelta.y > 0 ? 1.1 : 0.9
                var newScale = Math.max(0.1, Math.min(8.0, oldScale * factor))
                // Keep the canvas point under the cursor stable
                var canvasX = (wheel.x - viewportOffsetX) / oldScale
                var canvasY = (wheel.y - viewportOffsetY) / oldScale
                var cursorX = wheel.x
                var cursorY = wheel.y
                viewportScale = newScale
                viewportOffsetX = cursorX - canvasX * viewportScale
                viewportOffsetY = cursorY - canvasY * viewportScale
            }
        }
    }
}
