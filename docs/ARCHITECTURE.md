# Architektur und Entscheidungen

## Ziel des MVP

Der erste Stand deckt einen vollständigen kurzen Ablauf ab: globaler Hotkey, Rechteckauswahl, pixelgenaue Aufnahme, zerstörungsfreie Annotationen, Export in die Zwischenablage oder als PNG und Archivierung als Idee. Vollbild- und Fensteraufnahme, Timer und eine eigene Ideen-Galerie bleiben bewusst außerhalb des MVP.

## Aufbau

```text
Globaler Hotkey
      │
      ▼
AppKit-Auswahl-Overlay ──► ScreenCaptureKit ──► ScreenshotDocument
                                                    │
                                                    ▼
                                             SwiftUI-Editor
                                                    │
                                                    ▼
                                           Gemeinsamer Renderer
                                          ┌─────────┼─────────┐
                                          ▼         ▼         ▼
                                    Zwischenablage  PNG      Idee
```

`ScreenshotDocument` hält das unveränderte `CGImage` und eine Liste aus `Annotation`-Werten. Alle Punkte liegen in Pixelkoordinaten des Quellbildes mit Ursprung oben links. Der Editor skaliert sie nur für die Anzeige. Der Export zeichnet sie in Originalauflösung auf eine neue Bitmap.

## Aufnahme

Die App verwendet `SCScreenshotManager.captureImage(in:)` aus ScreenCaptureKit. Die API ist ab macOS 15.2 verfügbar, arbeitet mit einem globalen Rechteck in Bildschirmpunkten und unterstützt laut Apple mehrere Displays. Sie passt damit genau zur Bereichsauswahl und erspart einen Capture-Stream sowie das spätere Zusammensetzen einzelner Monitorbilder.

`CGWindowListCreateImage` wäre für ältere macOS-Versionen eine brauchbare Alternative. Für eine neue App ist ScreenCaptureKit die bessere Basis, weil Apple dort die aktuelle Capture-Entwicklung bündelt. Ein dauerhafter `SCStream` wäre für Video oder sehr häufige Aufnahmen sinnvoll, ist für einen einzelnen Screenshot aber unnötig.

Das Overlay ist ein rahmenloses AppKit-Fenster über der Vereinigungsfläche aller `NSScreen`-Frames. AppKit liefert Bildschirmkoordinaten mit Ursprung unten links. ScreenCaptureKit erwartet die Core-Graphics-Bildschirmkoordinaten mit Ursprung oben links. `ScreenCaptureService.coreGraphicsRect(from:)` führt genau diese Umrechnung aus. ScreenCaptureKit erzeugt anschließend die Retina-Pixelauflösung.

Das Overlay wird vor der Aufnahme ausgeblendet. Eine kurze Verzögerung von 80 Millisekunden gibt WindowServer Zeit, die Fläche neu zu zeichnen.

## Berechtigungen

Vor der ersten Auswahl prüft die App `CGPreflightScreenCaptureAccess`. Fehlt die Freigabe, löst `CGRequestScreenCaptureAccess` den macOS-Dialog aus. Je nach macOS-Version muss die App nach der Freigabe neu gestartet werden.

Der globale Hotkey verwendet `RegisterEventHotKey` aus Carbon. Diese API ist alt, funktioniert für diesen engen Zweck aber zuverlässig und benötigt keine Bedienungshilfen- oder Eingabeüberwachungsfreigabe. Ein `CGEventTap` wäre flexibler, würde aber zusätzliche Berechtigungen und mehr Fehlerfälle einführen. Eine kleine Swift-Abhängigkeit für Hotkeys wäre bequemer, bringt für eine einzelne Kombination im MVP aber keinen ausreichenden Vorteil.

## SwiftUI und AppKit

SwiftUI übernimmt Menüleistenmenü, Einstellungen, Werkzeugleiste und Editor-Canvas. AppKit übernimmt die Teile, bei denen genaue Fenster- und Ereigniskontrolle zählt: Vollbild-Overlay, Editorfenster, Speichern- und Ordnerdialoge, Zwischenablage und Hotkey-Aufzeichnung.

Die App läuft als `LSUIElement` und hat deshalb kein Dock-Symbol. Der Editor aktiviert die App nur während einer Bearbeitung.

## Ideenformat

Eine Idee ist eine einzelne PNG-Datei:

```text
2026-09-06_09-15-32.png
```

Eine spätere Galerie liest die PNG-Dateien und ihre Dateidaten direkt aus dem Ordner. Falls Titel, Notizen oder Tags dazukommen, speichert die App diese in einem einzelnen lokalen Index unter Application Support. So bleibt der vom Benutzer gewählte Ideenordner frei von technischen Begleitdateien.

## Nächste sinnvolle Schritte

1. Text direkt auf der Zeichenfläche bearbeiten statt im Eingabedialog.
2. Griffe zum Skalieren und Ändern vorhandener Annotationen ergänzen.
3. Ideen-Galerie als separates Fenster auf Basis der PNG-Dateien bauen.
4. Developer-ID-Signing, Notarisierung und bei Bedarf App-Sandbox mit Security-Scoped Bookmarks einrichten.
5. UI-Tests auf echten Monitoranordnungen durchführen, insbesondere bei verschiedenen Skalierungsfaktoren und Auswahl über Displaygrenzen hinweg.
