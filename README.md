# MaskShadePainter (MSP)

MVP digital mask painter built with Python 3.10+ and Qt Quick (PySide6). The app is focused on painting grayscale data (height/flow maps, temporal masks) with a Temporal Pen gradient tool.

## Project layout
- `main.py` – application entry point, registers the backend type and loads `main.qml`.
- `backend.py` – `PainterBackend` class (QQuickPaintedItem) handling the canvas image and drawing logic.
- `main.qml` – Qt Quick UI: tool selectors, sliders, and the viewport bound to `PainterBackend`.
- `requirements.txt` – dependencies (PySide6, numpy).

## Getting started
1) Create and activate a virtual environment  
   - Windows: `python -m venv venv && venv\Scripts\activate`  
   - macOS/Linux: `python -m venv venv && source venv/bin/activate`

2) Install dependencies  
   - `pip install -r requirements.txt`

3) Run the app  
   - `python main.py`

## Tooling overview
- **Brush**: draws continuous strokes between mouse moves using the configured size and gray value.
- **Eraser**: uses `CompositionMode_Clear` to wipe the alpha channel.
- **Temporal Pen**: captures the full path while the mouse is held, then bakes a linear gradient along the stroke between `tempStart` and `tempEnd` (0.0–1.0) on release. Degenerate zero-length strokes are handled safely.

## Notes
- The canvas is stored as an `ARGB32_Premultiplied` `QImage` and rendered via `QQuickPaintedItem` with an FBO render target for better GPU throughput.
- The UI keeps logic minimal; all drawing math and state live in `backend.py`.
