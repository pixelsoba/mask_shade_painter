from __future__ import annotations

import math
from dataclasses import dataclass
import time
from enum import Enum
from typing import List, Optional, Tuple

from PySide6.QtCore import QPointF, Property, QRectF, Signal, Slot, Qt
from PySide6.QtGui import QColor, QImage, QPainter, QPen
from PySide6.QtQuick import QQuickPaintedItem


def _clamp(value: float, min_value: float, max_value: float) -> float:
    return max(min_value, min(max_value, value))


class ToolMode(str, Enum):
    BRUSH = "brush"
    ERASER = "eraser"
    TEMPORAL = "temporal"
    FILL = "fill"
    LINEAR_GRADIENT = "linearGradient"
    RADIAL_GRADIENT = "radialGradient"
    PICKER = "picker"


class BlendMode(str, Enum):
    NORMAL = "normal"
    ADD = "add"
    MULTIPLY = "multiply"
    XOR = "xor"


class CanvasAnchor(str, Enum):
    TOP_LEFT = "topLeft"
    TOP_RIGHT = "topRight"
    BOTTOM_LEFT = "bottomLeft"
    BOTTOM_RIGHT = "bottomRight"
    CENTER = "center"


@dataclass
class Layer:
    name: str
    image: QImage
    opacity: float = 1.0
    visible: bool = True
    blend_mode: BlendMode = BlendMode.NORMAL


@dataclass
class LayerState:
    layers: List[Layer]
    active_index: int
    canvas_width: int
    canvas_height: int


class PainterBackend(QQuickPaintedItem):
    """
    Layered raster backend. Manages canvas pixel size, layer stack, and tools.
    """

    brushSizeChanged = Signal()
    grayValueChanged = Signal()
    toolModeChanged = Signal()
    tempStartChanged = Signal()
    tempEndChanged = Signal()
    tempPauseOnIdleChanged = Signal()
    fillToleranceChanged = Signal()
    fillSampleAllLayersChanged = Signal()
    fillContiguousChanged = Signal()
    layersChanged = Signal()
    activeLayerChanged = Signal()
    canvasSizeChanged = Signal()
    undoAvailableChanged = Signal()
    redoAvailableChanged = Signal()
    statsUpdated = Signal(str)

    DEFAULT_SIZE = 1024
    UNDO_LIMIT = 20

    def __init__(self, parent: Optional[QQuickPaintedItem] = None) -> None:
        super().__init__(parent)

        self.setRenderTarget(QQuickPaintedItem.FramebufferObject)
        self.setFillColor(Qt.transparent)

        self._brush_size: int = 20
        self._gray_value: int = 255
        self._tool_mode: ToolMode = ToolMode.BRUSH
        self._temp_start: float = 0.0
        self._temp_end: float = 1.0
        self._temp_pause_on_idle: bool = True
        self._fill_tolerance: int = 0  # 0-100 (% of 255)
        self._fill_sample_all_layers: bool = False
        self._fill_contiguous: bool = True

        self._canvas_width: int = self.DEFAULT_SIZE
        self._canvas_height: int = self.DEFAULT_SIZE

        base_layer = self._make_blank_layer("Layer 1")
        self._layers: List[Layer] = [base_layer]
        self._active_layer_index: int = 0

        self._composite: QImage = self._make_canvas_image()
        self._composite_dirty: bool = True

        self._temp_path: List[QPointF] = []
        self._temp_times: List[float] = []
        self._last_point: Optional[QPointF] = None
        self._stroke_begun: bool = False

        self._undo_stack: List[LayerState] = []
        self._redo_stack: List[LayerState] = []

    # --- Properties exposed to QML ---

    @Property(int, notify=brushSizeChanged)
    def brushSize(self) -> int:
        return self._brush_size

    @brushSize.setter
    def brushSize(self, value: int) -> None:
        value = max(1, int(value))
        if value != self._brush_size:
            self._brush_size = value
            self.brushSizeChanged.emit()

    @Property(int, notify=grayValueChanged)
    def grayValue(self) -> int:
        return self._gray_value

    @grayValue.setter
    def grayValue(self, value: int) -> None:
        value = int(_clamp(value, 0, 255))
        if value != self._gray_value:
            self._gray_value = value
            self.grayValueChanged.emit()

    @Property(str, notify=toolModeChanged)
    def toolMode(self) -> str:
        return self._tool_mode.value

    @toolMode.setter
    def toolMode(self, value: str) -> None:
        try:
            mode = ToolMode(value)
        except ValueError:
            mode = ToolMode.BRUSH
        if mode != self._tool_mode:
            self._tool_mode = mode
            self.toolModeChanged.emit()

    @Property(float, notify=tempStartChanged)
    def tempStart(self) -> float:
        return self._temp_start

    @tempStart.setter
    def tempStart(self, value: float) -> None:
        value = _clamp(float(value), 0.0, 1.0)
        if not math.isclose(value, self._temp_start):
            self._temp_start = value
            self.tempStartChanged.emit()

    @Property(float, notify=tempEndChanged)
    def tempEnd(self) -> float:
        return self._temp_end

    @tempEnd.setter
    def tempEnd(self, value: float) -> None:
        value = _clamp(float(value), 0.0, 1.0)
        if not math.isclose(value, self._temp_end):
            self._temp_end = value
            self.tempEndChanged.emit()

    @Property(bool, notify=tempPauseOnIdleChanged)
    def tempPauseOnIdle(self) -> bool:
        return self._temp_pause_on_idle

    @tempPauseOnIdle.setter
    def tempPauseOnIdle(self, value: bool) -> None:
        value = bool(value)
        if value != self._temp_pause_on_idle:
            self._temp_pause_on_idle = value
            self.tempPauseOnIdleChanged.emit()

    @Property(int, notify=fillToleranceChanged)
    def fillTolerance(self) -> int:
        return self._fill_tolerance

    @fillTolerance.setter
    def fillTolerance(self, value: int) -> None:
        value = int(_clamp(value, 0, 100))
        if value != self._fill_tolerance:
            self._fill_tolerance = value
            self.fillToleranceChanged.emit()

    @Property(bool, notify=fillSampleAllLayersChanged)
    def fillSampleAllLayers(self) -> bool:
        return self._fill_sample_all_layers

    @fillSampleAllLayers.setter
    def fillSampleAllLayers(self, value: bool) -> None:
        value = bool(value)
        if value != self._fill_sample_all_layers:
            self._fill_sample_all_layers = value
            self.fillSampleAllLayersChanged.emit()

    @Property(bool, notify=fillContiguousChanged)
    def fillContiguous(self) -> bool:
        return self._fill_contiguous

    @fillContiguous.setter
    def fillContiguous(self, value: bool) -> None:
        value = bool(value)
        if value != self._fill_contiguous:
            self._fill_contiguous = value
            self.fillContiguousChanged.emit()

    @Property(int, notify=canvasSizeChanged)
    def canvasWidth(self) -> int:
        return self._canvas_width

    @Property(int, notify=canvasSizeChanged)
    def canvasHeight(self) -> int:
        return self._canvas_height

    @Property(int, notify=activeLayerChanged)
    def activeLayerIndex(self) -> int:
        return self._active_layer_index

    @Property("QVariantList", notify=layersChanged)
    def layersModel(self) -> List[dict]:
        return [
            {
                "name": layer.name,
                "opacity": layer.opacity,
                "visible": layer.visible,
                "blendMode": layer.blend_mode.value,
                "index": idx,
                "active": idx == self._active_layer_index,
            }
            for idx, layer in enumerate(self._layers)
        ]

    @Property(bool, notify=undoAvailableChanged)
    def undoAvailable(self) -> bool:
        return len(self._undo_stack) > 0

    @Property(bool, notify=redoAvailableChanged)
    def redoAvailable(self) -> bool:
        return len(self._redo_stack) > 0

    # --- Rendering ---

    def paint(self, painter: QPainter) -> None:
        self._ensure_composite()
        painter.drawImage(0, 0, self._composite)

        if self._tool_mode == ToolMode.TEMPORAL and len(self._temp_path) > 1:
            preview_pen = QPen(QColor(255, 50, 50, 128), 2)
            painter.setPen(preview_pen)
            painter.drawPolyline(self._temp_path)

    def _ensure_composite(self) -> None:
        if not self._composite_dirty:
            return

        composite = self._make_canvas_image(fill_transparent=True)
        painter = QPainter(composite)
        painter.setRenderHint(QPainter.Antialiasing)

        for layer in self._layers:
            if not layer.visible:
                continue
            painter.setOpacity(_clamp(layer.opacity, 0.0, 1.0))
            painter.setCompositionMode(self._qt_composition_mode(layer.blend_mode))
            painter.drawImage(0, 0, layer.image)

        painter.end()
        self._composite = composite
        self._composite_dirty = False

    # --- Geometry handling (keep item size independent from canvas size) ---

    def geometryChanged(self, new_geometry: QRectF, old_geometry: QRectF) -> None:
        super().geometryChanged(new_geometry, old_geometry)
        self.update()

    # --- Slots called from QML ---

    @Slot(float, float)
    def inputPressed(self, x: float, y: float) -> None:
        point = QPointF(x, y)
        self._last_point = point

        if self._tool_mode == ToolMode.TEMPORAL:
            self._begin_stroke()
            self._temp_path = [point]
            self._temp_times = [self._monotonic_ms()]
            self.update()
        elif self._tool_mode == ToolMode.FILL:
            self._begin_stroke()
            self._apply_fill(point)
            self._stroke_begun = False
        else:
            self._begin_stroke()
            self._paint_stroke(point, point)

    @Slot(float, float)
    def inputMoved(self, x: float, y: float) -> None:
        point = QPointF(x, y)

        if self._tool_mode == ToolMode.TEMPORAL:
            if not self._temp_path:
                self._temp_path = [point]
                self._temp_times = [self._monotonic_ms()]
                self.update()
                return

            if (point - self._temp_path[-1]).manhattanLength() > 1.5:
                self._temp_path.append(point)
                self._temp_times.append(self._monotonic_ms())
                self.update()
        elif self._tool_mode == ToolMode.FILL:
            # Fill only on press for now
            return
        else:
            if self._last_point is None:
                self._last_point = point
            self._paint_stroke(self._last_point, point)
            self._last_point = point

    @Slot(float, float)
    def inputReleased(self, x: float, y: float) -> None:
        point = QPointF(x, y)

        if self._tool_mode == ToolMode.TEMPORAL:
            if not self._temp_path:
                self._temp_path = [point]
                self._temp_times = [self._monotonic_ms()]
            else:
                self._temp_path.append(point)
                self._temp_times.append(self._monotonic_ms())
            self._bake_temporal_gradient()
            self._temp_path = []
            self._temp_times = []
            self.update()
        elif self._tool_mode == ToolMode.FILL:
            return
        else:
            if self._last_point is None:
                self._last_point = point
            self._paint_stroke(self._last_point, point)
            self._last_point = None

        self._stroke_begun = False

    @Slot(int, int, str)
    def resizeCanvas(self, width: int, height: int, anchor: str = "center") -> None:
        width = max(1, int(width))
        height = max(1, int(height))
        try:
            anchor_enum = CanvasAnchor(anchor)
        except ValueError:
            anchor_enum = CanvasAnchor.CENTER

        if width == self._canvas_width and height == self._canvas_height:
            return

        self._push_undo_state()
        self._canvas_width = width
        self._canvas_height = height

        for idx, layer in enumerate(self._layers):
            self._layers[idx] = self._resize_layer(layer, width, height, anchor_enum)

        self._mark_composite_dirty()
        self.canvasSizeChanged.emit()
        self.layersChanged.emit()
        self.update()

    @Slot()
    def addLayer(self) -> None:
        self._push_undo_state()
        layer = self._make_blank_layer(f"Layer {len(self._layers)+1}")
        self._layers.append(layer)
        self._active_layer_index = len(self._layers) - 1
        self._mark_layers_changed()

    @Slot(int)
    def duplicateLayer(self, index: int) -> None:
        if index < 0 or index >= len(self._layers):
            return
        self._push_undo_state()
        source = self._layers[index]
        copy = self._clone_layer(source)
        copy.name = f"{source.name} copy"
        self._layers.insert(index + 1, copy)
        self._active_layer_index = index + 1
        self._mark_layers_changed()

    @Slot()
    def duplicateActiveLayer(self) -> None:
        self.duplicateLayer(self._active_layer_index)

    @Slot(int)
    def deleteLayer(self, index: int) -> None:
        if len(self._layers) <= 1:
            return
        if index < 0 or index >= len(self._layers):
            return
        self._push_undo_state()
        del self._layers[index]
        self._active_layer_index = max(0, min(self._active_layer_index, len(self._layers) - 1))
        self._mark_layers_changed()

    @Slot()
    def deleteActiveLayer(self) -> None:
        self.deleteLayer(self._active_layer_index)

    @Slot(int)
    def setActiveLayer(self, index: int) -> None:
        if index < 0 or index >= len(self._layers):
            return
        if index != self._active_layer_index:
            self._active_layer_index = index
            self.activeLayerChanged.emit()
            self.layersChanged.emit()

    @Slot(int, float)
    def setLayerOpacity(self, index: int, opacity: float) -> None:
        if index < 0 or index >= len(self._layers):
            return
        opacity = _clamp(opacity, 0.0, 1.0)
        if math.isclose(opacity, self._layers[index].opacity):
            return
        self._push_undo_state()
        self._layers[index].opacity = opacity
        self._mark_layers_changed()

    @Slot(int, bool)
    def setLayerVisible(self, index: int, visible: bool) -> None:
        if index < 0 or index >= len(self._layers):
            return
        if visible == self._layers[index].visible:
            return
        self._push_undo_state()
        self._layers[index].visible = visible
        self._mark_layers_changed()

    @Slot(int, str)
    def setLayerBlendMode(self, index: int, mode: str) -> None:
        if index < 0 or index >= len(self._layers):
            return
        try:
            blend = BlendMode(mode)
        except ValueError:
            blend = BlendMode.NORMAL
        if blend == self._layers[index].blend_mode:
            return
        self._push_undo_state()
        self._layers[index].blend_mode = blend
        self._mark_layers_changed()

    @Slot(int, int)
    def moveLayer(self, from_index: int, to_index: int) -> None:
        if from_index < 0 or from_index >= len(self._layers):
            return
        to_index = max(0, min(to_index, len(self._layers) - 1))
        if from_index == to_index:
            return
        self._push_undo_state()
        layer = self._layers.pop(from_index)
        self._layers.insert(to_index, layer)
        if self._active_layer_index == from_index:
            self._active_layer_index = to_index
        self._mark_layers_changed()

    @Slot(int)
    def moveLayerUp(self, index: int) -> None:
        self.moveLayer(index, index + 1)

    @Slot(int)
    def moveLayerDown(self, index: int) -> None:
        self.moveLayer(index, index - 1)

    @Slot(int, int, int)
    def applyHistogram(self, index: int, min_value: int, max_value: int, center_value: int) -> None:
        if index < 0 or index >= len(self._layers):
            return
        min_value = int(_clamp(min_value, 0, 255))
        max_value = int(_clamp(max_value, 0, 255))
        center_value = int(_clamp(center_value, 0, 255))
        if max_value <= min_value:
            return

        self._push_undo_state()
        layer = self._layers[index]
        img = layer.image
        width, height = img.width(), img.height()
        min_f = float(min_value)
        max_f = float(max_value)
        inv_range = 1.0 / (max_f - min_f)
        center_shift = (center_value / 255.0) - 0.5

        for y in range(height):
            for x in range(width):
                c = img.pixelColor(x, y)
                v = c.red()
                norm = (v - min_f) * inv_range
                norm = _clamp(norm + center_shift, 0.0, 1.0)
                out_v = int(_clamp(norm * 255.0, 0.0, 255.0))
                c.setRed(out_v)
                c.setGreen(out_v)
                c.setBlue(out_v)
                img.setPixelColor(x, y, c)

        self._mark_layers_changed()

    @Slot()
    def undo(self) -> None:
        if not self._undo_stack:
            return
        state = self._undo_stack.pop()
        self._redo_stack.append(self._capture_state())
        self._restore_state(state)
        self._update_undo_redo_flags()

    @Slot()
    def redo(self) -> None:
        if not self._redo_stack:
            return
        state = self._redo_stack.pop()
        self._undo_stack.append(self._capture_state())
        self._restore_state(state)
        self._update_undo_redo_flags()

    # --- Internal logic ---

    def _make_canvas_image(self, fill_transparent: bool = True) -> QImage:
        image = QImage(self._canvas_width, self._canvas_height, QImage.Format_ARGB32_Premultiplied)
        if fill_transparent:
            image.fill(Qt.transparent)
        else:
            image.fill(QColor(0, 0, 0, 255))
        return image

    def _make_blank_layer(self, name: str) -> Layer:
        img = self._make_canvas_image(fill_transparent=True)
        return Layer(name=name, image=img)

    def _clone_layer(self, layer: Layer) -> Layer:
        return Layer(
            name=layer.name,
            image=layer.image.copy(),
            opacity=layer.opacity,
            visible=layer.visible,
            blend_mode=layer.blend_mode,
        )

    def _begin_stroke(self) -> None:
        if not self._stroke_begun:
            self._push_undo_state()
            self._stroke_begun = True

    def _active_layer(self) -> Optional[Layer]:
        if not self._layers:
            return None
        return self._layers[self._active_layer_index]

    def _paint_stroke(self, start: QPointF, end: QPointF) -> None:
        layer = self._active_layer()
        if layer is None:
            return
        painter = QPainter(layer.image)
        painter.setRenderHint(QPainter.Antialiasing)

        if self._tool_mode == ToolMode.ERASER:
            painter.setCompositionMode(QPainter.CompositionMode_Clear)
            pen_color = Qt.transparent
        else:
            value = int(_clamp(self._gray_value, 0, 255))
            pen_color = QColor(value, value, value)

        pen = QPen(pen_color, self._brush_size, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
        painter.setPen(pen)
        painter.drawLine(start, end)
        painter.end()

        self._mark_composite_dirty()
        self.update()

    def _bake_temporal_gradient(self) -> None:
        layer = self._active_layer()
        if layer is None:
            return

        if len(self._temp_path) < 2:
            value = int(_clamp(self._temp_start * 255.0, 0, 255))
            self._stroke_single_point(self._temp_path[0], value)
            return

        use_time = not self._temp_pause_on_idle and len(self._temp_times) == len(self._temp_path)

        if use_time:
            cumulative = [0.0]
            total = 0.0
            start_time = self._temp_times[0]
            last_time = start_time
            for t in self._temp_times[1:]:
                delta = max(0.0, t - last_time)
                total += delta
                cumulative.append(total)
                last_time = t
            if total <= 1e-6:
                use_time = False
        if not use_time:
            cumulative = [0.0]
            total = 0.0
            for i in range(1, len(self._temp_path)):
                segment = self._temp_path[i] - self._temp_path[i - 1]
                distance = math.hypot(segment.x(), segment.y())
                total += distance
                cumulative.append(total)
            if total <= 1e-6:
                value = int(_clamp(self._temp_start * 255.0, 0, 255))
                self._stroke_single_point(self._temp_path[0], value)
                return

        start_v = self._temp_start * 255.0
        end_v = self._temp_end * 255.0

        painter = QPainter(layer.image)
        painter.setRenderHint(QPainter.Antialiasing)

        for i in range(1, len(self._temp_path)):
            t1 = cumulative[i - 1] / total
            t2 = cumulative[i] / total
            t_mid = (t1 + t2) * 0.5
            value = int(_clamp(start_v + (end_v - start_v) * t_mid, 0, 255))

            pen = QPen(QColor(value, value, value), self._brush_size, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
            painter.setPen(pen)
            painter.drawLine(self._temp_path[i - 1], self._temp_path[i])

        painter.end()
        self._mark_composite_dirty()
        self.update()

    def _stroke_single_point(self, point: QPointF, value: int) -> None:
        layer = self._active_layer()
        if layer is None:
            return
        painter = QPainter(layer.image)
        painter.setRenderHint(QPainter.Antialiasing)
        painter.setPen(Qt.NoPen)
        painter.setBrush(QColor(value, value, value))

        radius = self._brush_size * 0.5
        painter.drawEllipse(QRectF(point.x() - radius, point.y() - radius, self._brush_size, self._brush_size))
        painter.end()

        self._mark_composite_dirty()
        self.update()

    def _apply_fill(self, point: QPointF) -> None:
        layer = self._active_layer()
        if layer is None:
            return

        x = int(point.x())
        y = int(point.y())
        if x < 0 or y < 0 or x >= self._canvas_width or y >= self._canvas_height:
            return

        # Reference image for sampling
        if self._fill_sample_all_layers:
            self._ensure_composite()
            src_img = self._composite
        else:
            src_img = layer.image

        seed_color = src_img.pixelColor(x, y)
        seed_val = seed_color.red()
        target_val = int(_clamp(self._gray_value, 0, 255))

        if seed_val == target_val and not self._fill_sample_all_layers:
            # Nothing to do if replacing same value on same layer
            return

        tol = int(_clamp(self._fill_tolerance, 0, 100))
        threshold = int(255 * (tol / 100.0))

        if self._fill_contiguous:
            self._flood_fill(layer.image, src_img, x, y, seed_val, target_val, threshold)
        else:
            self._global_fill(layer.image, src_img, seed_val, target_val, threshold)

        self._mark_composite_dirty()
        self.update()

    def _within_tol(self, value: int, seed: int, threshold: int) -> bool:
        return abs(value - seed) <= threshold

    def _flood_fill(self, dst_img: QImage, src_img: QImage, x: int, y: int, seed_val: int, target_val: int, threshold: int) -> None:
        width = src_img.width()
        height = src_img.height()
        visited = bytearray(width * height)
        stack = [(x, y)]
        seed_channel = seed_val

        while stack:
            cx, cy = stack.pop()
            idx = cy * width + cx
            if visited[idx]:
                continue
            visited[idx] = 1

            c = src_img.pixelColor(cx, cy)
            if not self._within_tol(c.red(), seed_channel, threshold):
                continue

            dst_img.setPixelColor(cx, cy, QColor(target_val, target_val, target_val))

            if cx > 0:
                stack.append((cx - 1, cy))
            if cx < width - 1:
                stack.append((cx + 1, cy))
            if cy > 0:
                stack.append((cx, cy - 1))
            if cy < height - 1:
                stack.append((cx, cy + 1))

    def _global_fill(self, dst_img: QImage, src_img: QImage, seed_val: int, target_val: int, threshold: int) -> None:
        width = src_img.width()
        height = src_img.height()
        seed_channel = seed_val
        for cy in range(height):
            for cx in range(width):
                c = src_img.pixelColor(cx, cy)
                if self._within_tol(c.red(), seed_channel, threshold):
                    dst_img.setPixelColor(cx, cy, QColor(target_val, target_val, target_val))

    def _qt_composition_mode(self, blend: BlendMode) -> QPainter.CompositionMode:
        if blend == BlendMode.ADD:
            return QPainter.CompositionMode_Plus
        if blend == BlendMode.MULTIPLY:
            return QPainter.CompositionMode_Multiply
        if blend == BlendMode.XOR:
            return QPainter.CompositionMode_Xor
        return QPainter.CompositionMode_SourceOver

    def _resize_layer(self, layer: Layer, new_w: int, new_h: int, anchor: CanvasAnchor) -> Layer:
        new_image = QImage(new_w, new_h, QImage.Format_ARGB32_Premultiplied)
        new_image.fill(Qt.transparent)

        old_w, old_h = layer.image.width(), layer.image.height()
        dx, dy = self._anchor_offset(old_w, old_h, new_w, new_h, anchor)

        painter = QPainter(new_image)
        painter.setCompositionMode(QPainter.CompositionMode_Source)
        painter.drawImage(dx, dy, layer.image)
        painter.end()

        return Layer(
            name=layer.name,
            image=new_image,
            opacity=layer.opacity,
            visible=layer.visible,
            blend_mode=layer.blend_mode,
        )

    def _anchor_offset(self, old_w: int, old_h: int, new_w: int, new_h: int, anchor: CanvasAnchor) -> Tuple[int, int]:
        if anchor == CanvasAnchor.CENTER:
            dx = (new_w - old_w) // 2
            dy = (new_h - old_h) // 2
        elif anchor == CanvasAnchor.TOP_RIGHT:
            dx = new_w - old_w
            dy = 0
        elif anchor == CanvasAnchor.BOTTOM_LEFT:
            dx = 0
            dy = new_h - old_h
        elif anchor == CanvasAnchor.BOTTOM_RIGHT:
            dx = new_w - old_w
            dy = new_h - old_h
        else:
            dx = 0
            dy = 0
        return dx, dy

    def _push_undo_state(self) -> None:
        state = self._capture_state()
        self._undo_stack.append(state)
        if len(self._undo_stack) > self.UNDO_LIMIT:
            self._undo_stack.pop(0)
        self._redo_stack.clear()
        self._update_undo_redo_flags()

    def _capture_state(self) -> LayerState:
        snapshot_layers = [self._clone_layer(layer) for layer in self._layers]
        return LayerState(
            layers=snapshot_layers,
            active_index=self._active_layer_index,
            canvas_width=self._canvas_width,
            canvas_height=self._canvas_height,
        )

    def _restore_state(self, state: LayerState) -> None:
        size_changed = (state.canvas_width != self._canvas_width) or (state.canvas_height != self._canvas_height)
        self._layers = [self._clone_layer(layer) for layer in state.layers]
        self._active_layer_index = max(0, min(state.active_index, len(self._layers) - 1))
        self._canvas_width = state.canvas_width
        self._canvas_height = state.canvas_height
        self._composite = self._make_canvas_image(fill_transparent=True)
        self._mark_layers_changed()
        if size_changed:
            self.canvasSizeChanged.emit()

    def _mark_composite_dirty(self) -> None:
        self._composite_dirty = True

    def _mark_layers_changed(self) -> None:
        self._mark_composite_dirty()
        self.layersChanged.emit()
        self.activeLayerChanged.emit()
        self.update()

    def _update_undo_redo_flags(self) -> None:
        self.undoAvailableChanged.emit()
        self.redoAvailableChanged.emit()

    def _monotonic_ms(self) -> float:
        return time.monotonic() * 1000.0
