# Konzept: iCloud-Sync

Status: **Code implementiert, noch nicht auf echten Geräten getestet und nicht in der README beworben.** Aktuell gilt:

- Merge-Logik (`SyncMerge.swift`), Store-Anbindung (`CloudSync.swift`) und `KeyValueSyncBackend` sind fertig und per Fake getestet.
- Der Schalter „Mit iCloud synchronisieren“ (`SyncSettingsView`, Ansicht „Level“) erscheint nur in Builds mit dem Compile-Flag `ICLOUD_SYNC`. Das ist für signierte iOS-Geräte-Builds gesetzt (zusammen mit `FiSiTrainer-iOS.entitlements`); Simulator, CI und die ad-hoc signierte Mac-DMG haben weder Flag noch Entitlement und zeigen den Schalter nicht.
- Offen: Developer-ID-Signierung für den Mac, Synchronisation von Haustier-Auswahl und Ausstattung (aktuell nur XP, Lernstand und Prüfungsverlauf; Belohnungen leiten sich aus der kombinierten XP ab), Zwei-Geräte-Test.

Voraussetzung ist ein bezahlter Apple Developer Account (iCloud-Capability, Provisioning-Profile). Das Konzept hält fest, wie der Sync mit der bestehenden Persistenz (siehe [ARCHITECTURE.md](ARCHITECTURE.md#persistenz)) zusammenpasst, damit die Umsetzung in einem Zug möglich ist.

## Ziele und Nicht-Ziele

- Fortschritt (XP, Level, Abzeichen, Haustier-Auswahl und -Ausstattung, adaptive Lernstände, Prüfungshistorie) soll zwischen Mac, iPad und iPhone desselben Apple-Kontos übereinstimmen.
- Die App bleibt offline voll nutzbar. Die lokale Datei ist weiterhin die Quelle der Wahrheit, iCloud ist ein Spiegel.
- Kein eigener Server, kein Konto, keine Drittanbieter-Pakete. Der Sync ist **optional** (Schalter, standardmäßig aus) und für Nutzer ohne iCloud unsichtbar.
- **Nicht synchronisiert:** laufende Runden (`GameSession`, `SubnetSession`, `ExamSession`) samt `QuestionTiming`. Sie sind gerätegebunden, die Zeitmessung läuft nach Wanduhr weiter und passt nicht zu zwei Geräten.

## Technikwahl

| Option | Passt zu | Nachteil |
| --- | --- | --- |
| **`NSUbiquitousKeyValueStore`** (iCloud Key-Value) | Kleine Zustände (< 1 MB gesamt, max. 1024 Schlüssel); iOS 5+/macOS 10.7+, kein Netzwerk-Entitlement nötig; wenig Code | Last-Writer-Wins pro Schlüssel, also muss die App selbst zusammenführen |
| iCloud Drive (Ubiquity-Container, JSON-Dateien) | Größere Dokumente | `NSFileCoordinator`/`NSFilePresenter`, Konflikte auf Dateiebene (`NSFileVersion`), Sandbox-Eigenheiten, mehr Code |
| CloudKit (SwiftData oder `CKSyncEngine`) | Viele Datensätze, feines Merge | Persistenz müsste neu gebaut werden, deutlich mehr Aufwand |

**Empfehlung: `NSUbiquitousKeyValueStore`.** Die zu synchronisierenden Daten sind klein: rund 1000 `LearningRecord`s (je ca. 60 Byte, gesamt ca. 60 KB), vier Zähler-Strukturen, höchstens 20 `ExamResult`s und die Belohnungsdaten. Pro Store wird **ein JSON-Blob** unter einem festen Schlüssel abgelegt (`sync.port`, `sync.subnet`, `sync.exam`, `sync.rewards`). Die Zusammenführung passiert in der App: Jedes Gerät liest Remote-Änderungen, führt sie mit dem lokalen Stand zusammen und schreibt das Ergebnis zurück. Sind die Merge-Regeln unten kommutativ, assoziativ und idempotent, konvergieren alle Geräte, auch wenn iCloud gleichzeitige Schreibzugriffe nur nach „letzter gewinnt“ auflöst.

Sollten die Daten später über ~700 KB wachsen (Alarmgrenze), ist CloudKit der nächste Schritt; die Merge-Funktionen unten bleiben dann wiederverwendbar.

## Merge-Regeln

Alle Regeln sind reine Funktionen `merge(local, remote) -> merged` und werden getrennt vom Speicher getestet.

| Datum | Regel | Begründung |
| --- | --- | --- |
| `PlayerProgress.totalXP`, `completedRounds`, `correctAnswers`, `answeredQuestions` | **Zähler pro Gerät** (`[deviceID: Int]`), Summe ergibt den Wert; beim Zusammenführen pro Gerät das Maximum | Reines Maximum würde parallel verdiente XP verschlucken |
| Altbestand (Spielstand vor dem ersten Sync) | als `baseline` pro Store gespeichert; beim Zusammenführen Maximum | Vorhandene Spielstände bleiben lesbar, siehe Kompatibilität |
| `bestScore` | Maximum | monoton |
| `LearningRecord` | der Datensatz mit der größeren `attempts`-Zahl gewinnt; bei Gleichstand der mit mehr `correct` | verlustbehaftet, aber ohne Zeitstempel nicht exakter möglich; betrifft nur die Gewichtung der Fragenauswahl |
| `RewardStore.totalXP` | wird **nicht** direkt synchronisiert, sondern nach dem Merge aus den drei Spielen neu berechnet und über `updateXP` angehoben | bleibt Höchststand, Haustiere und Ausstattung werden nie wieder gesperrt |
| `interactionCounts` (Bindung) | pro Schlüssel Maximum | monoton |
| `selectedPet`, `outfitsByPet`, `toysByPet` | pro Haustier „letzte Änderung gewinnt“ mit Zeitstempel (`updatedAt`) | Einstellung, kein Zähler; beim Laden wird weiterhin gegen `unlockLevel` validiert |
| `[ExamResult]` | Vereinigung, Duplikate nach (Datum, Modus, Fach, Ergebnis) entfernen, neueste 20 | Historie |
| Zurücksetzen eines Spiels | **Epoche** (`resetEpoch: Int`) pro Store; höhere Epoche gewinnt und verwirft ältere Zähler | sonst würde der Sync einen Reset sofort wieder rückgängig machen |

Der Reset-Dialog muss dann darauf hinweisen, dass der Reset auf allen Geräten gilt.

## Sicherheitsregeln (aus `AGENTS.md`)

- **Beschädigte Dateien nie überschreiben:** Ist `maySave == false` (kaputte lokale Datei), wird weder hochgeladen noch zusammengeführt. Erst die bestätigte Wiederherstellung (`resetProgress()`) öffnet den Sync wieder.
- **Ungültige Remote-Daten werden ignoriert.** Dieselben `isValid`-Prüfungen wie beim Laden einer lokalen Datei gelten für den Remote-Blob. Schlägt eine Prüfung fehl, bleibt der lokale Stand unverändert und es erscheint ein Hinweis; nichts wird überschrieben.
- **Neue Felder sind optional mit Default** (`deviceID`, Zähler pro Gerät, `baseline`, `resetEpoch`, `updatedAt`). Alte JSON-Dateien müssen unverändert lesbar bleiben.
- IDs und `rawValue`s bleiben Persistenzschlüssel, auch im Remote-Blob.

## Architektur

Neue Dateien (alle in `project.yml`-Quellordner `FiSiTrainer`, nach dem Anlegen `xcodegen generate`):

- `SyncMerge.swift`: reine Merge-Funktionen, keine Abhängigkeit zu iCloud.
- `CloudSync.swift`: Protokoll `SyncBackend` (`read(key)`, `write(key, data)`, Änderungs-Callback), Implementierung `KeyValueSyncBackend` auf `NSUbiquitousKeyValueStore`, Verfügbarkeit über `FileManager.default.ubiquityIdentityToken`.
- Die vier Stores bekommen einen optionalen `sync: SyncBackend?` (Standard `nil`) im Initializer, analog zu den bereits injizierten `saveURL` und `now`. Nach jedem `save()` wird bei aktivem Sync der Blob geschrieben; bei `didChangeExternallyNotification` (Gründe `serverChange` und `initialSyncChange`) werden Remote-Daten geprüft, zusammengeführt, gespeichert und veröffentlicht (`@Published`).
- Beim ersten Aktivieren: lokalen Stand hochladen, Remote lesen, zusammenführen. Das ist wegen der kommutativen Regeln ohne Rückfrage möglich; ein kurzer Hinweis („Fortschritt von iPhone und Mac wurde zusammengeführt“) genügt.
- UI: Schalter „Mit iCloud synchronisieren“ in „Level“ (iOS) bzw. als Abschnitt in der Level-Ansicht (Mac); ausgegraut mit Erklärung, wenn kein iCloud-Konto aktiv ist. Statuszeile „Zuletzt synchronisiert: …“.

## Konto, Signierung, Pipeline

1. **App-ID** `de.linolaske.fisitrainer` im Developer-Portal anlegen und **iCloud (Key-Value Storage)** aktivieren. Das Entitlement `com.apple.developer.ubiquity-kvstore-identifier` = `$(TeamIdentifierPrefix)$(CFBundleIdentifier)` kommt in die Entitlements-Dateien: die bestehende macOS-Datei erweitern und eine eigene für iOS anlegen (aktuell ist `CODE_SIGN_ENTITLEMENTS` nur für `sdk=macosx*` gesetzt). Der Sandbox-Eintrag für ausgehende Verbindungen ist dafür nach heutigem Stand nicht nötig; beim ersten echten Test gegenprüfen.
2. **Mac-Release:** iCloud-Entitlements sind eingeschränkt und brauchen ein Provisioning-Profile. Die ad-hoc signierte DMG kann sie nicht nutzen. Der Mac-Release muss dann mit **Developer ID** signiert und **notarisiert** werden (`Scripts/package-release.sh` anpassen: `CODE_SIGNING_ALLOWED=NO` und `codesign --sign -` entfallen, Notarisierung per `notarytool`, Profile als Secret). Damit verschwindet auch die Gatekeeper-Warnung.
3. **iOS/TestFlight:** Archiv mit `xcodebuild archive`, Export und Upload per App-Store-Connect-API-Schlüssel. Zugangsdaten gehören in GitHub-Secrets und nur in den Schritt, der sie braucht. `ITSAppUsesNonExemptEncryption = NO` ist bereits gesetzt.
4. **Datenschutz:** Synchronisierte Daten liegen im privaten iCloud-Bereich des Nutzers; der Entwickler hat keinen Zugriff. Für das App-Store-Datenschutzlabel ist „Daten werden nicht erhoben“ weiter zutreffend. Die README-Aussage „ohne Konto, lokal gespeichert“ muss um den optionalen iCloud-Sync ergänzt werden.

## Altdaten und Bundle-ID

Mit der Umstellung auf `de.linolaske.fisitrainer` hat die Mac-App einen neuen Sandbox-Container; Spielstände aus `de.fisitrainer.mac` sind für die neue App nicht lesbar und lassen sich auch nicht über iCloud übernehmen. Der Sync beginnt daher bei jedem Gerät mit dem Stand der neuen ID.

## Tests

- Merge-Funktionen als Eigenschaftstests: kommutativ (`merge(a,b) == merge(b,a)`), assoziativ, idempotent; Beispiele für parallel verdiente XP, Reset-Epoche, ungültige Remote-Daten.
- `SyncBackend` als In-Memory-Fake: zwei Store-Paare tauschen Änderungen aus, ohne iCloud. Zeit und Speicherort sind bereits injizierbar.
- Altformat-Test: JSON ohne die neuen Felder lädt unverändert (analog zu `testLegacyStartupWithoutRewardFileAndOlderRewardSchema`).
- Manuelle Prüfung mit zwei echten Geräten, bevor die Funktion in einem Release aktiviert wird.

## Umsetzungsschritte

1. `SyncMerge.swift` samt Tests (ohne iCloud).
2. Felder und Stores erweitern, `SyncBackend` einführen, mit dem Fake testen.
3. `KeyValueSyncBackend`, Schalter und Statusanzeige in der UI.
4. Entitlements, Signierung und Pipeline (Developer ID, TestFlight).
5. Zwei-Geräte-Test, README und Datenschutztext aktualisieren, Release.
