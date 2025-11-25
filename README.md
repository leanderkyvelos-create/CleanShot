# CleanShot

Eine Offline-App, die Screenshots lokal mit Apple Core ML und Vision auf dem Gerät kategorisiert – ohne API-Keys, 100 % privat.

## Features
- **Sofort einsatzbereit:** nutzt `VNClassifyImageRequest` und `VNRecognizeTextRequest` ohne externe Services.
- **Screenshot-Kategorien:** Chat/Messenger, Textdokument, Meme, UI/Website, Foto, unbekannt.
- **Heuristiken:** Textdichte, Helligkeit, Farbdurchschnitt sowie Top-CoreML-Labels fließen in die Entscheidung ein.
- **SwiftUI-Demo:** Auswahl eines Screenshots per `PhotosPicker`, Anzeige der Top-Kategorie und weiterer Treffer.

## Projektstruktur
- `Package.swift` – SwiftPM Manifest (iOS 15+).
- `Sources/CleanShotApp/` – SwiftUI-App + Klassifizierungs-Engine.

## Projekt in Xcode öffnen
1. Repository klonen oder laden: `git clone <repo-url>`.
2. Im Finder auf `Package.swift` doppelklicken, um das SwiftPM-Paket in Xcode zu öffnen. Alternativ: Xcode starten, **File ▸ Open** und `Package.swift` wählen.
3. Das Schema **CleanShotApp** auswählen und ein iOS-Simulatorgerät oder ein angeschlossenes iPhone einstellen.
4. Mit **⌘R** bauen & ausführen. Falls Xcode ein Signing-Profil verlangt, im Tab „Signing & Capabilities“ dein Team auswählen.

## Aufbau
1. Öffne das Repository in Xcode (iOS 15+). SwiftPM erzeugt die App automatisch.
2. Erlaube Fotobibliotheks-Zugriff; wähle einen Screenshot über den "Screenshot wählen"-Button.
3. Die App führt Vision-Requests offline aus und zeigt Kategorie, Alternativen und Diagnostik (Textblöcke, Helligkeit, Top-Labels).

## Beta-Release (0.1.0-beta)
- Status: Öffentliche Beta – voll funktionsfähig, noch ohne automatisierte Tests.
- Installation: In Xcode über "Product > Run" auf einem iOS-15+-Gerät bzw. Simulator starten.
- Fokus: Offline-Klassifizierung, schnelle Heuristiken, einfache UI für Screenshot-Import.
- Feedback: Bitte Issues für Erkennungsfehler oder Wunsch-Kategorien erstellen.

## Wichtige Klassen
- `ScreenshotClassifier` – führt Vision-Requests (Text + generische Bildklassifikation) aus und wendet Heuristiken für Kategorien an.
- `ContentView` – SwiftUI-Oberfläche mit `PhotosPicker` und Resultat-Card.

## Erweiterungen
- Eigene `.mlmodel`-Datei einbinden (z. B. MobileNetV2 oder YOLO) und in `VNCoreMLModel` laden, um Labels zu verfeinern.
- Grenzwerte in `pickCategory` anpassen, um andere Kategorien wie "Belege", "Whiteboard" oder "Game UI" zu erkennen.
- Optional Textposts erkennen: `VNRecognizeTextRequest` auf `.accurate` setzen und Spracherkennung aktivieren.
