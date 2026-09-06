# Shoot It

Shoot It ist eine kleine native macOS-Menüleisten-App für Bereichs-Screenshots und schnelle Annotationen.

## Voraussetzungen

- Apple Silicon Mac
- macOS 15.2 oder neuer
- Xcode 16 oder neuer

## Bauen und starten

```sh
./scripts/build-app.sh
open '.build/Shoot It.app'
```

Beim ersten Screenshot fragt macOS nach der Berechtigung für Bildschirmaufnahmen. Falls macOS es verlangt, muss die App danach neu gestartet werden.

Der Standard-Hotkey ist `Cmd+Shift+1`. Er lässt sich in den Einstellungen ändern.

## Bedienung

1. Hotkey drücken oder "Bereich aufnehmen" im Menü wählen.
2. Mit dem Fadenkreuz einen Bereich aufziehen. `Esc` bricht ab.
3. Im Editor Werkzeug, Farbe und Strichstärke wählen.
4. Ergebnis kopieren, als PNG sichern, verwerfen oder als Idee archivieren.

`Cmd+C`, `Cmd+S`, `Cmd+Z`, `Cmd+Shift+Z`, Delete und Backspace funktionieren im Editor.

## Architektur

- `Capture`: AppKit-Auswahlfenster und ScreenCaptureKit-Aufnahme
- `Editor`: SwiftUI-Canvas, Werkzeugleiste und Fenstersteuerung
- `Models`: zerstörungsfreies Dokument und Annotationen
- `Export`: gemeinsamer Renderer für Zwischenablage, PNG und Ideen
- `HotKey`: globaler Carbon-Hotkey ohne Accessibility-Berechtigung
- `Preferences`: lokale Einstellungen via UserDefaults

Annotationen bleiben bis zum Export vom Quellbild getrennt. Eine Idee wird als einzelne PNG-Datei gespeichert. Eine spätere Galerie kann den Ordner direkt einlesen.

## Bewusste Grenzen des MVP

- Nur rechteckige Bereichsaufnahme
- Ein Editorfenster zurzeit
- Text wird in einem kleinen Eingabedialog erfasst
- Annotationen können als Ganzes verschoben, aber noch nicht skaliert werden
- Die Ideen-Galerie ist noch ein Finder-Ordner
- Kein App-Store-Sandboxing oder Developer-ID-Release-Signing
