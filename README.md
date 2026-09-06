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
3. Im Editor Werkzeug, Farbe und Strichstärke wählen. Ausgewählte Annotationen lassen sich an ihren Griffen skalieren.
4. Ergebnis kopieren, als PNG sichern, verwerfen oder als Idee archivieren.

`Cmd+C`, `Cmd+S`, `Cmd+Z`, `Cmd+Shift+Z`, Delete und Backspace funktionieren im Editor.

Das Textwerkzeug öffnet den Editor direkt auf der Zeichenfläche. `Return` übernimmt den Text, `Shift+Return` fügt einen Zeilenumbruch ein und `Esc` bricht die Eingabe ab. Ein Doppelklick bearbeitet vorhandenen Text erneut. Beim Skalieren hält `Shift` das Seitenverhältnis von Rechtecken und Ellipsen. Pfeile und Linien rasten damit in 45-Grad-Schritten ein.

"Ideen öffnen" zeigt alle PNG-Dateien aus dem gewählten Ideenordner in einer eigenen Galerie. Doppelklick öffnet eine Idee in Vorschau. Kopieren, Finder-Anzeige und Löschen in den Papierkorb stehen im Kontextmenü und für die Auswahl am unteren Fensterrand bereit.

## Architektur

- `Capture`: AppKit-Auswahlfenster und ScreenCaptureKit-Aufnahme
- `Editor`: SwiftUI-Canvas, Werkzeugleiste und Fenstersteuerung
- `Models`: zerstörungsfreies Dokument und Annotationen
- `Export`: gemeinsamer Renderer für Zwischenablage, PNG und Ideen
- `Gallery`: PNG-Katalog, Ordnerbeobachtung und begrenzter Thumbnail-Cache
- `HotKey`: globaler Carbon-Hotkey ohne Accessibility-Berechtigung
- `Preferences`: lokale Einstellungen via UserDefaults

Annotationen bleiben bis zum Export vom Quellbild getrennt. Eine Idee wird als einzelne PNG-Datei gespeichert. Die Galerie liest vorhandene PNG-Dateien ohne Migration und ohne Begleitdateien.

## Bewusste Grenzen des MVP

- Nur rechteckige Bereichsaufnahme
- Ein Editorfenster zurzeit
- Die Galerie liest nur PNG-Dateien direkt im Ideenordner, nicht in Unterordnern. Titel, Notizen, Tags und ein Metadatenindex gibt es noch nicht.
- Text unterstützt manuelle Zeilenumbrüche, aber noch keine automatische Umbruchbreite, Schriftfamilien oder Schriftschnitte.
- Annotationen lassen sich noch nicht drehen. Freihandlinien werden nur proportional skaliert.
- Kein App-Store-Sandboxing oder Developer-ID-Release-Signing
