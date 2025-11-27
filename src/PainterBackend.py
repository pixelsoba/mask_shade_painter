import math
from PySide6.QtQuick import QQuickPaintedItem
from PySide6.QtGui import QImage, QPainter, QColor, QPen, QBrush
from PySide6.QtCore import Qt, QPointF, Property, Signal, Slot, QObject

class PainterBackend(QQuickPaintedItem):
    """
    Ce composant est le 'Canvas' exposé à QML.
    Il gère l'image en mémoire et les outils (Temporal Pen, Brush).
    """
    
    # Signals pour notifier QML si besoin (ex: fin d'un calcul long)
    statsUpdated = Signal(str)

    def __init__(self, parent=None):
        super().__init__(parent)
        
        # Configuration interne
        self.setRenderTarget(QQuickPaintedItem.FramebufferObject)
        self.setFillColor(QColor("#222222")) # Fond gris foncé
        
        # L'image principale (Le calque actif pour la V0)
        self._image = QImage(1024, 1024, QImage.Format_ARGB32_Premultiplied)
        self._image.fill(QColor(0, 0, 0, 255)) # Fond noir opaque
        
        # État des outils
        self._brush_size = 20
        self._gray_value = 255 # 0-255
        self._tool_mode = "brush" # brush, eraser, temporal
        
        # Pour le Temporal Pen
        self._temp_path = [] # Liste de QPointF
        self._temp_start = 0.0
        self._temp_end = 1.0

    # --- Properties exposées à QML ---
    
    @Property(int)
    def brushSize(self): return self._brush_size
    @brushSize.setter
    def brushSize(self, val): self._brush_size = val

    @Property(int)
    def grayValue(self): return self._gray_value
    @grayValue.setter
    def grayValue(self, val): self._gray_value = val
    
    @Property(str)
    def toolMode(self): return self._tool_mode
    @toolMode.setter
    def toolMode(self, val): self._tool_mode = val

    @Property(float)
    def tempStart(self): return self._temp_start
    @tempStart.setter
    def tempStart(self, val): self._temp_start = val

    @Property(float)
    def tempEnd(self): return self._temp_end
    @tempEnd.setter
    def tempEnd(self, val): self._temp_end = val

    # --- Méthode de rendu (Appelée par QML quand on update()) ---
    def paint(self, painter: QPainter):
        # On dessine simplement notre QImage interne sur l'item QML
        # C'est ici qu'on gère le zoom/pan si on le voulait
        # Pour la V0, on dessine en (0,0)
        painter.drawImage(0, 0, self._image)
        
        # Preview du trait en cours (Optionnel, ex: fil rouge pour Temporal Pen)
        if self._tool_mode == "temporal" and len(self._temp_path) > 1:
            pen = QPen(QColor(255, 50, 50, 128), 2)
            painter.setPen(pen)
            painter.drawPolyline(self._temp_path)

    # --- Slots appelés depuis le MouseArea dans QML ---

    @Slot(float, float)
    def inputPressed(self, x, y):
        self._last_point = QPointF(x, y)
        
        if self._tool_mode == "temporal":
            self._temp_path = [QPointF(x, y)]
            self.update() # Déclenche paint() pour voir le fil rouge
        else:
            # Dessin immédiat (un point)
            self._paint_stroke(self._last_point, self._last_point)

    @Slot(float, float)
    def inputMoved(self, x, y):
        current_point = QPointF(x, y)
        
        if self._tool_mode == "temporal":
            # On accumule juste les points
            if (current_point - self._temp_path[-1]).manhattanLength() > 2:
                self._temp_path.append(current_point)
                self.update() # Refresh preview
        else:
            # Dessin direct
            self._paint_stroke(self._last_point, current_point)
            self._last_point = current_point

    @Slot(float, float)
    def inputReleased(self, x, y):
        if self._tool_mode == "temporal":
            self._temp_path.append(QPointF(x, y))
            self._bake_temporal_gradient()
            self._temp_path = [] # Reset
            self.update()

    # --- Logique Interne ---

    def _paint_stroke(self, p1, p2):
        painter = QPainter(self._image)
        painter.setRenderHint(QPainter.Antialiasing)
        
        color_val = self._gray_value
        color = QColor(color_val, color_val, color_val)
        
        if self._tool_mode == "eraser":
            painter.setCompositionMode(QPainter.CompositionMode_Clear)
            pen = QPen(Qt.transparent, self._brush_size, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
        else:
            # Mode normal
            pen = QPen(color, self._brush_size, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
            
        painter.setPen(pen)
        painter.drawLine(p1, p2)
        painter.end()
        
        self.update() # Demande à QML de redessiner l'item

    def _bake_temporal_gradient(self):
        """ La Killer Feature: Recalculer le gradient sur le chemin """
        if len(self._temp_path) < 2: return

        # 1. Calculer la longueur totale
        total_len = 0.0
        dists = [0.0]
        
        import math
        for i in range(1, len(self._temp_path)):
            diff = self._temp_path[i] - self._temp_path[i-1]
            d = math.hypot(diff.x(), diff.y())
            total_len += d
            dists.append(total_len)
            
        if total_len == 0: return

        # 2. Dessiner dans l'image
        painter = QPainter(self._image)
        painter.setRenderHint(QPainter.Antialiasing)
        
        start_v = self._temp_start * 255
        end_v = self._temp_end * 255
        
        for i in range(1, len(self._temp_path)):
            p1 = self._temp_path[i-1]
            p2 = self._temp_path[i]
            
            # Interpolation linéaire basique basée sur la distance parcourue
            prog1 = dists[i-1] / total_len
            prog2 = dists[i] / total_len
            avg_prog = (prog1 + prog2) / 2.0
            
            val = start_v + (end_v - start_v) * avg_prog
            val_int = int(max(0, min(255, val)))
            
            color = QColor(val_int, val_int, val_int)
            pen = QPen(color, self._brush_size, Qt.SolidLine, Qt.RoundCap, Qt.RoundJoin)
            
            painter.setPen(pen)
            painter.drawLine(p1, p2)
            
        painter.end()