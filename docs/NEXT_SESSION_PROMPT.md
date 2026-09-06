# Starter-Prompt für die nächste Session

Arbeite im bestehenden Repository der nativen macOS-App "Shoot It". Lies zuerst `README.md` und `docs/ARCHITECTURE.md`, prüfe den aktuellen Code und baue die App sowie die Tests, bevor du etwas änderst.

Der vorhandene MVP funktioniert im realen Einsatz. Bewahre den schnellen Ablauf aus Hotkey, Bereichsauswahl, Editor und Export. Vermeide neue externe Abhängigkeiten, sofern AppKit oder SwiftUI die Aufgabe vernünftig lösen. Unterstützt wird macOS 15.2 oder neuer auf Apple Silicon.

Setze als nächsten Schritt diese drei Bereiche um:

## 1. Ideen-Galerie

- Ersetze den bisherigen Finder-Aufruf im Menüpunkt "Ideen öffnen" durch ein eigenes Galerie-Fenster.
- Lies alle PNG-Dateien aus dem in den Einstellungen gewählten Ideenordner ein. Erzeuge keine JSON-Sidecars.
- Zeige eine performante Thumbnail-Übersicht mit Dateiname und Aufnahmedatum.
- Aktualisiere die Galerie, wenn Dateien hinzukommen, verschwinden oder der Ideenordner geändert wird.
- Ermögliche Öffnen in der Vorschau, Kopieren, Anzeigen im Finder und Löschen nach Bestätigung.
- Ergänze Suche nach Dateiname und Datum.
- Halte die Architektur offen für Titel, Notizen und Tags. Falls du dafür bereits Metadaten einführst, verwende einen einzigen lokalen Index unter Application Support, keine Begleitdatei pro PNG.
- Lade große Bilder nicht dauerhaft in voller Auflösung in den Arbeitsspeicher. Nutze gecachte Thumbnails.

## 2. Direkte Textbearbeitung

- Entferne den modalen Texteingabedialog.
- Ein Klick mit dem Textwerkzeug soll direkt auf der Zeichenfläche einen fokussierten Texteditor anlegen.
- Return übernimmt den Text, Escape bricht ab. Definiere ein nachvollziehbares Verhalten für Zeilenumbrüche.
- Ein vorhandenes Textelement soll sich per Doppelklick erneut bearbeiten lassen.
- Auswahl, Verschieben, Undo, Redo, Delete und Export müssen mit Text weiterhin funktionieren.
- Position und Größe bleiben in Pixelkoordinaten des Quellbildes gespeichert.

## 3. Größenänderung von Annotationen

- Zeige für das ausgewählte Element gut erkennbare Auswahlgriffe.
- Pfeile und Linien brauchen Griffe für Start und Ende.
- Rechtecke und Ellipsen sollen sich an Ecken und Kanten skalieren lassen.
- Text soll über einen passenden Griff skaliert werden. Die Schriftgröße gehört dafür explizit ins Annotation-Modell.
- Freihandlinien dürfen zunächst proportional über ihre Begrenzungsbox skaliert werden.
- Halte während Shift das Seitenverhältnis, soweit das für das Werkzeug sinnvoll ist.
- Eine komplette Größenänderung muss genau einen Undo-Schritt erzeugen.
- Begrenze Griffe und Hit-Testing sinnvoll, damit kleine oder stark herausgezoomte Annotationen bedienbar bleiben.

## Vorgehen und Abnahme

Trenne Galerie, Textbearbeitung und Transformationslogik in kleine, testbare Komponenten. Passe das bestehende Modell nur so weit an, wie die Funktionen es verlangen. Bestehende Ideen sind reine PNG-Dateien und müssen ohne Migration sichtbar sein.

Ergänze Tests für Galerie-Sortierung und Filterung, Thumbnail-Cache-Schlüssel, Textänderungen, Geometrie der Auswahlgriffe und Undo-Verhalten bei Transformationen. Baue am Ende das Release-App-Bundle mit `./scripts/build-app.sh release`, führe alle Tests aus und dokumentiere verbleibende Grenzen. Ändere nichts an GitHub, erstelle keinen Release und pushe nicht, solange ich das nicht ausdrücklich verlange.
