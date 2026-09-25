# Entwicklung und Spielregeln

[Zurück zur Projektübersicht](../README.md) · [Architektur und Wartung](ARCHITECTURE.md)

Eine detaillierte technische Referenz (Dateikarte, Datenfluss, Prüfungswissen im Detail, Persistenzformate, Rezepte für Änderungen) findest du in [ARCHITECTURE.md](ARCHITECTURE.md).

FiSi Trainer ist eine SwiftUI-App für macOS 14 oder neuer. SceneKit zeichnet die Haustiere und ihre Ausstattung aus nativen Geometrien. Es gibt keine zusätzlichen Swift-Pakete und keinen eigenen Netzwerkdienst.

## Build und Tests

Zum Kompilieren wird **Xcode 26 oder neuer** benötigt; die CI verwendet Xcode 26.6. Die fertige App läuft ab macOS 14.

`FiSiTrainer.xcodeproj` ist eingecheckt. Öffne das Scheme **FiSiTrainer** in Xcode oder nutze die Kommandozeile:

```sh
xcodebuild test -project FiSiTrainer.xcodeproj -scheme FiSiTrainer \
  -destination 'platform=macOS' -derivedDataPath build CODE_SIGNING_ALLOWED=NO
```

`project.yml` ist die XcodeGen-Quelle. Nach einer Änderung daran `xcodegen generate` ausführen und das erzeugte Projekt mit einreichen. `.github/workflows/build.yml` testet auf Pushes und Pull Requests gegen `main`.

Wenn ein GitHub Release mit einem Tag wie `v1.0.0` veröffentlicht wird, baut `.github/workflows/release.yml` automatisch eine App mit `arm64`- und `x86_64`-Architektur. `Scripts/package-release.sh` erstellt `FiSiTrainer-v1.0.0-macOS-universal.dmg` und die dazugehörige `.dmg.sha256`-Datei. Release-Tags müssen das Format `vMAJOR.MINOR.PATCH` haben. Ein lokaler Probelauf ist mit `bash Scripts/package-release.sh /tmp/fisi-release v1.0.0` möglich.

Der Build erhält nur eine ad-hoc-Signatur; eine Developer-ID-Signatur und Apple-Notarisierung sind derzeit nicht Teil des Release-Prozesses.

## DMG gestalten

`Packaging/dmg-settings.py` legt Fenstergröße, Symbolpositionen und die Programme-Verknüpfung fest. Das Hintergrundbild liegt in `Packaging/`; die bearbeitbare Zeichnung wird mit `Scripts/render-dmg-background.swift` erzeugt. Das DMG-Fenster zeigt die App und eine Verknüpfung auf `/Applications`, damit die Installation per Ziehen funktioniert.

`Scripts/create-dmg.sh APP_PATH OUTPUT_DMG` verpackt eine bereits signierte App ohne erneuten Build. Die Python-Werkzeuge für die DMG werden mit festen Versionen aus `Packaging/requirements-dmg.txt` in einer isolierten Umgebung installiert. Sie sind ausschließlich Build-Werkzeuge und werden nicht mit der App ausgeliefert. Die Erstellung benötigt macOS und Python 3.10 oder neuer; Finder-Automation ist dafür nicht erforderlich.

Bei Änderungen das erzeugte Image mit `hdiutil verify` prüfen, einhängen und kontrollieren, dass Signatur, Hintergrund, Symbolpositionen und die Programme-Verknüpfung erhalten bleiben. Finder-Metadaten und Hintergrund werden in der DMG mitgeliefert, sodass GitHub Actions dasselbe Fenster erzeugt.

## Trainingslogik

Das **Port-Quiz** stellt zehn Fragen pro Runde zu Dienst und Standardport in beiden Richtungen oder zu TCP/UDP. Der Katalog umfasst 40 Dienste. Portnummern orientieren sich an der [IANA Service Name and Port Number Registry](https://www.iana.org/assignments/service-names-port-numbers/); Dienste können in echten Netzen auf anderen Ports laufen. Bereits begonnene Runden bleiben mit ihren Fragen erhalten.

Der **Subnetz-Sprint** fragt IPv4-Präfixe von `/16` bis `/30`, Masken und nutzbare Hostadressen ab. `/31` und `/32` verwenden Sonderfälle und werden deshalb nicht mit der allgemeinen Hostformel abgefragt. Beide Spiele zeigen nach einer Antwort die Erklärung und unterstützen **1–4** zur Auswahl sowie **Return** zum Fortfahren.

Beide Spiele messen die Zeit pro Frage. Eine richtige Antwort gibt 25 XP und bei schneller Antwort zusätzlich:

| Antwortzeit | Extra-XP |
| --- | ---: |
| Bis 10 Sekunden | 15 |
| Bis 20 Sekunden | 10 |
| Bis 30 Sekunden | 5 |
| Danach | 0 |

Eine falsche Antwort gibt 5 XP ohne Tempo-Bonus. Es gibt kein Zeitlimit. Die laufende Zeit bleibt auch bei Ansichtswechsel oder geschlossener App erhalten und wird beim Antworten eingefroren. Bereits beantwortete alte Fragen erhalten keinen nachträglichen Bonus.

`AdaptiveLearning.swift` speichert Treffer und Fehler pro Dienst/Präfix und Fragetyp. Fehler erhöhen die Auswahlwahrscheinlichkeit in neuen Runden; die letzten fünf Antworten beeinflussen die Gewichtung. Neue und sichere Themen bleiben enthalten, innerhalb einer Runde werden Dienste beziehungsweise Präfixe nicht wiederholt. Ein Reset des jeweiligen Spiels setzt dessen Lernhistorie zurück.

### Prüfungswissen

Die Arena **Prüfungswissen** nutzt einen gemeinsamen Katalog (`ExamCatalog*.swift`) mit Karten für Einfachauswahl, Aussagen, Mehrfachauswahl, Zuordnung, Reihenfolge, Lückentext und Fakten. `ExamTaskFactory` erzeugt daraus Runden; `ExamCalculation` generiert Rechenaufgaben mit zufälligen Werten. Richtige Antworten stehen im Katalog an erster Stelle und werden beim Erzeugen gemischt. Karten-IDs sind Speicherschlüssel und dürfen nicht geändert werden.

Die Aufgaben sind eigene Formulierungen zu den Themen früherer IHK-Prüfungen und geben den Rechtsstand 2026 vereinfacht wieder. Originalaufgaben der IHK/ZPA werden aus urheberrechtlichen Gründen nicht übernommen.

XP und Tempo-Bonus folgen denselben Regeln wie in den anderen Spielen; eine abgeschlossene Runde bringt 50 XP, die Prüfungssimulation 100 XP. In der Simulation gibt es erst am Ende eine Auflösung mit Teilpunkten bei Mehrfach-, Zuordnungs- und Reihenfolgeaufgaben und der IHK-Note (ab 92 % sehr gut, 81 % gut, 67 % befriedigend, 50 % ausreichend, 30 % mangelhaft). Fortschritt liegt in `exam-progress.json`.

## Fortschritt, Haustiere und Daten

Die XP aller Spiele (Port-Quiz, Subnetz-Sprint, Prüfungswissen) zählen für die gemeinsame Roadmap. Alle 250 XP steigt das Level; die Roadmap zeigt 100 Level. Katze, Fuchs und Drache werden auf Level 2, 5 und 10 freigeschaltet. Kleidung und Spielzeug erscheinen je nach Level, kosten aber keine XP. Die Auswahl wird pro Tier gespeichert. Interaktionen mit Haustieren vergeben keine Lern-XP.

Für Belohnungen zählt der höchste erreichte gemeinsame XP-Stand. Der Reset eines einzelnen Spiels nimmt bereits verdiente Level und Haustiere nicht zurück; neue Level folgen, sobald die aktuelle Summe den bisherigen Höchststand übersteigt.

Runden, XP, Lernhistorie und Belohnungen liegen als JSON im Application-Support-Verzeichnis der App, bei aktivierter Sandbox in ihrem Container. Beschädigte Belohnungsdaten werden nicht still überschrieben; die App bietet eine ausdrücklich bestätigte Wiederherstellung mit Sicherung der alten Datei.

Die Haustiere bestehen aus SceneKit-Geometrien. Die Kamera passt sich beim Tierwechsel und bei Größenänderungen an; Ziehen dreht die Ansicht, Doppelklick setzt sie zurück. Die macOS-Einstellung **Bewegung reduzieren** vereinfacht dauerhafte Bewegungen und Spielanimationen.

## Lokale KI

`PetIntelligence.swift` verwendet nur Apples `SystemLanguageModel.default` aus Foundation Models, wenn macOS 26 oder neuer und Apple Intelligence bereitstehen. Ohne Modell sind vorbereitete Tipps und Ermutigungen verfügbar und entsprechend gekennzeichnet. KI-Anfragen starten nur auf Knopfdruck, Chatnachrichten werden nicht dauerhaft gespeichert. Der Prompt begrenzt Verlauf und Eingabe; vor der Abgabe enthält er nur Hinweise zur Aufgabe, danach auch die hinterlegte Erklärung. Die Auswertung der Spiele verwendet kein Sprachmodell.

## Dateien und App-Icon

- `Models.swift`, `GameStore.swift`, `SubnetTrainer.swift`: Fragen, Regeln und Spielstände.
- `ExamModels.swift`, `ExamCatalog*.swift`, `ExamTaskFactory.swift`, `ExamCalculation.swift`, `ExamStore.swift`, `ExamViews.swift`: Prüfungswissen-Arena.
- `AdaptiveLearning.swift`, `QuestionTiming.swift`: Themengewichtung und Zeitbonus.
- `Rewards.swift`, `PetAccessories.swift`, `PetWardrobeView.swift`: Roadmap, Freischaltungen und Ausstattung.
- `PetScene.swift`, `PetDetailGeometry.swift`, `PetAccessoryGeometry.swift`: 3D-Szene, Haustiere, Futter und Gegenstände.
- `PetCompanionView.swift`, `PetCompanionMessages.swift`, `TrainingPetContext.swift`: Aufgabenbegleiter und vorbereitete Texte.
- `PetIntelligence.swift`, `PetChatView.swift`: lokaler KI-Zugriff, Chat und optionale Sprachausgabe.
- `FiSiTrainerTests/`: Tests für Regeln, Speicherung und Geometrie.

Das editierbare App-Icon liegt unter `FiSiTrainer/AppIcon.icon`; seine drei SVG-Ebenen liegen in `Assets`. Xcodes Icon Composer rendert das Icon und beim Build das klassische `AppIcon.icns`. `ASSETCATALOG_COMPILER_APPICON_NAME: AppIcon` in `project.yml` bindet es ein. Das Vorschaubild für das README ist `Documentation/AppIcon.png`.
