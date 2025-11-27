from __future__ import annotations

import os
import sys
from typing import Optional

from PySide6.QtGui import QGuiApplication
from PySide6.QtQml import QQmlApplicationEngine, qmlRegisterType
from PySide6.QtCore import QUrl, QFileSystemWatcher

from backend import PainterBackend


def load_qml(engine: QQmlApplicationEngine, qml_url: QUrl) -> None:
    # Clean previous roots to avoid leaks
    for obj in engine.rootObjects():
        obj.deleteLater()
    engine.clearComponentCache()
    engine.load(qml_url)


def main() -> int:
    app = QGuiApplication(sys.argv)
    qmlRegisterType(PainterBackend, "MSP", 1, 0, "PainterBackend")

    engine = QQmlApplicationEngine()
    qml_path = os.path.join(os.path.dirname(__file__), "main.qml")
    qml_url = QUrl.fromLocalFile(qml_path)
    load_qml(engine, qml_url)

    watcher = QFileSystemWatcher()
    watcher.addPath(qml_path)
    watcher.addPath(os.path.dirname(qml_path))

    def on_qml_changed(_path: str) -> None:
        if os.path.exists(qml_path):
            load_qml(engine, qml_url)
            # Re-add if editors swap files
            if qml_path not in watcher.files():
                watcher.addPath(qml_path)

    watcher.fileChanged.connect(on_qml_changed)
    watcher.directoryChanged.connect(on_qml_changed)

    if not engine.rootObjects():
        return -1

    return app.exec()


if __name__ == "__main__":
    sys.exit(main())
