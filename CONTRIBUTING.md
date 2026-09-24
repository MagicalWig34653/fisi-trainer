# Zu FiSi Trainer beitragen

Danke für Fehlerberichte, neue Tests und Verbesserungen am Lernstoff. Beschreibe bei einem Fehler möglichst die App-Version, macOS-Version, den betroffenen Trainingsmodus und die Schritte zum Nachstellen. Teile keine persönlichen Spielstände oder Zugangsdaten.

Für agentengestützte Änderungen gelten zusätzlich die Hinweise in [AGENTS.md](AGENTS.md). `.editorconfig` legt die Formatierung fest.

## Lokal entwickeln

Du brauchst einen Mac mit **Xcode 26 oder neuer** (die CI nutzt Xcode 26.6) und für Änderungen an `project.yml` zusätzlich [XcodeGen](https://github.com/yonaskolb/XcodeGen). Das eingecheckte `FiSiTrainer.xcodeproj` lässt sich direkt in Xcode öffnen; Scheme **FiSiTrainer**, Ziel **My Mac**. **⌘R** startet die App, **⌘U** die Tests.

Nach Änderungen an `project.yml` das Projekt neu erzeugen und die Änderung am Xcode-Projekt mit einreichen:

```sh
xcodegen generate
xcodebuild -list -project FiSiTrainer.xcodeproj
```

Vor einem Pull Request die Tests ausführen:

```sh
xcodebuild test \
  -project FiSiTrainer.xcodeproj \
  -scheme FiSiTrainer \
  -destination 'platform=macOS' \
  -derivedDataPath build \
  CODE_SIGNING_ALLOWED=NO
```

Der CI-Workflow in `.github/workflows/build.yml` führt die macOS-Tests für Pushes und Pull Requests auf `main` aus. [Entwicklungsdetails](Documentation/DEVELOPMENT.md) erklären Speicherung, Spielregeln und Dateiaufbau.

## Beiträge vorbereiten

Halte Änderungen überschaubar und ergänze Tests für neue Spielregeln oder Speicherdaten. Neue Fragen sollten fachlich überprüfbare Erklärungen haben; bei Ports sind die IANA-Registrierung und übliche Nutzung zu unterscheiden. Verwende für Bilder, Texte und Klänge nur selbst erstelltes oder nachweislich passend lizenziertes Material. Das Projekt wird unter [AGPL-3.0-only](LICENSE) veröffentlicht; eingereichte Beiträge müssen dazu passen.

FiSi Trainer ist ein unabhängiges Lernprojekt. Bitte stelle Beiträge nicht als offizielle IHK-Prüfungsfragen oder als von einer Prüfungseinrichtung bestätigt dar.
