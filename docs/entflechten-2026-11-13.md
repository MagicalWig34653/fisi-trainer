# Entflechten-Analyse 2026-11-13

Nur Analyse, kein Code geändert. Schwerpunkt: Stores, Logik, Aufgabentypen, Sync. Die ExamCatalog*-Dateien sind Daten und keine Befunde.

## Graph-Zusammenfassung

- Vier gleich gebaute Stores (`GameStore`, `SubnetStore`, `ExamStore`, `RewardStore`) plus `LearnPathStore`. Jeder hat eigenes Laden/Speichern, eigene Beschädigungs-Sicherung und (außer LearnPath) eigenes Sync-Setup.
- `FiSiTrainerApp.swift` verdrahtet Stores per `onChange` (kombinierte XP → Rewards und LearnPath, Bindungspunkte, Rundenende). Die Kopplung steckt in der App-Struktur, nicht in den Stores.
- Git-Historie (150 Commits): am häufigsten gemeinsam geändert sind `ContentView.swift` (13), `ExamCatalogIHK.swift` (12), `FiSiTrainerApp.swift` (9), `Rewards.swift` (7), `ExamViews.swift` (7), `ExamStore.swift` (6).
- Größte Dateien: `ContentView.swift` 1214 Zeilen, `ExamViews.swift` 993, `Rewards.swift` 884, `PetScene.swift` 869.

Bewusste Entscheidungen, keine Befunde: kein Drittanbieter-Paket; Reward-XP als Höchststand und nicht synchronisiert; Sync nur in iOS-Gerätebuilds; `AnyView`/`LazyPage` wegen des 1-MB-Stacks (STATUS.md).

## Befunde

**Versteckte Kopplung**

1. Persistenz-Block steht fünfmal fast identisch: `GameStore.swift:186-230`, `SubnetTrainer.swift:210-250`, `ExamStore.swift:358-400`, `Rewards.swift:454-510`, `LearnPath.swift:286-316` (load, save, `maySave`, `saveError`, Datei `*.corrupt.<UUID>.json`). Ein Fix am Verhalten bei beschädigten Dateien muss fünfmal gemacht werden.
2. Reset mit Sicherung der beschädigten Datei: `GameStore.swift:126-140`, `SubnetTrainer.swift:150-160`, `ExamStore.swift:221-232`, `Rewards.swift:375-385` fast wortgleich. In `LearnPath.swift:299-301` fehlt der Fehlerzweig (siehe 9).
3. `enableSync`/`disableSync`/`applySynced` fast wortgleich in `GameStore.swift:161-185`, `SubnetTrainer.swift:185-210`, `ExamStore.swift:332-357`. Nur der Schlüssel (`sync.port`, `sync.subnet`, `sync.exam`) und `applySynced` (Verlauf nur bei Exam) unterscheiden sich.
4. Die Liste der synchronisierten Stores steht an drei Stellen: `CloudSync.swift` (attach, enable, disable je vier Stores), `FiSiTrainerApp.swift:26` (`attach(game:subnet:exam:rewards:)`). Ein neuer Store (z. B. LearnPath) wird leicht vergessen. Das ist bereits passiert: `LearnPathStore` hat weder `enableSync` noch Eintrag in `ICLOUD-SYNC.md`. Tagesziel, Streak und Lektionen bleiben je Gerät, obwohl XP geräteübergreifend ist. `observeTotalXP` verbucht dann auf Gerät B XP-Sprünge, die auf Gerät A erarbeitet wurden, als Tages-XP.
5. XP-Regeln sind in drei Stores kopiert: `progress.totalXP += 25 + bonus` / `+= 5` bei falsch in `GameStore.swift:100`, `SubnetTrainer.swift:126`, `ExamStore.swift:174`. Ebenso der Tempo-Bonus-Ablauf (`availableBonus`, `earnedBonus`, `speedBonusTotal`) und die Prüfung `speedBonusTotal < 0` in der Session-Validierung (`GameStore.swift:287`, `SubnetTrainer.swift:310`, `ExamStore.swift:426`). Die Regel „Falsch bekommt keinen Bonus“ muss überall gleich bleiben.
6. Die kombinierte XP wird zweimal berechnet: `FiSiTrainerApp.swift:51` (`combinedXP`) und `Rewards.swift:600` (Überlauf-sichere Summe). Zwei Quellen für dieselbe Zahl.
7. Lerntyp-Schlüssel `"exam:\(taskID)"` (`ExamStore.swift:275`) wird von `AdaptiveLearning`-Nutzern, `dueCards` und `answer` über `learningKey` gebildet; `GameStore`/`SubnetStore` nutzen eigene Schlüsselformen. Konvention, die man wissen muss.
8. Lektion-Ablauf ist über drei Dateien verteilt: `LearnPath.swift:startLesson/roundFinished` (merkt sich Thema und Startzeit), `ExamStore.start(lesson:)` mit `session.isLesson`, und `FiSiTrainerApp.swift:35` (`onChange` von `completedRounds`). Erkennung des Rundenendes hängt an einem Zähler und an `startedAt`-Gleichheit. Wird die Runde beim Sync ersetzt oder `pending` geht beim Neustart verloren (es wird nicht gespeichert), zählt die Lektion nicht.

**Unnötige Kopplung**

9. `LearnPath.swift:299-301`: `try? moveItem` verschluckt den Fehler und setzt `maySave = true`. Die Stores nehmen dort den Fehlerzweig mit `saveError`. Bei fehlgeschlagener Sicherung wird die beschädigte Datei später überschrieben. Das widerspricht der AGENTS.md-Regel („beschädigte Spielstände erhalten“). Sonderfall: verschluckter Fehler.
10. `ExamMode`-Sonderfälle `mode == .exam` an mindestens 14 Stellen: `ExamStore.swift:33, 97, 180, 428`, `ExamTaskFactory.swift:36, 49` (eigener Zweig), `ExamViews.swift:195, 317, 336, 344, 349, 354, 371, 383`. Die Prüfungssimulation hat eigene Regeln (kein Thema, keine Auflösung, Note, Teilpunkte), die an Aufrufern verstreut sind statt im Modus.
11. `ExamMode.calc` ähnlich: `ExamTaskFactory.swift:37/50`, `ExamViews.swift:605`. Zahleneingabe und Wortbank-Lücke (Welle 4) hängen an `ExamTask.Kind`, aber `ExamViews.swift:605` fragt den Modus statt der Aufgabenart.
12. Aufgabentypen gibt es in drei parallelen Listen: `ExamCard` (7 Fälle, `ExamModels.swift:99`), `ExamMode` (9 Fälle, mit `title`/`summary`/`symbol`/`roundLength` je als eigenes `switch`, `ExamModels.swift:135-190`), `ExamTask.Kind` (4 Fälle, vier `switch` für `isValid`, `accepts`, `credit`, `describe`). Die Zuordnung steht in `ExamTaskFactory.cards(...)` (`switch (mode, card)`, Zeile 18) und `task(from:)` (Zeile 104). Ein neuer Aufgabentyp berührt fünf bis sechs Stellen; der Compiler hilft nur dort, wo kein `default` steht (`availableCount`, `makeRound` haben eins).
13. `ExamCard` hat `id` und `topic` als zwei getrennte `switch` über alle sieben Fälle mit langen Tupelmustern (`ExamModels.swift:111-128`). Jeder neue Fall braucht zwei Muster mit richtiger Stelligkeit.
14. `ExamStore.start` und `startReview` bauen Sessions getrennt (`ExamStore.swift:95-110, 130-145`); `isLesson` ist ein optionales Flag (`Bool?`) für Wiederholung und Lektion zugleich, ohne zu sagen, welcher Fall es ist.
15. `ContentView.swift` (1214 Zeilen, in der Historie am häufigsten geändert) enthält Spielseiten, Dashboard und Level-Ansicht. `page == .game || .subnet || .exam` taucht mehrfach auf (`ContentView.swift:32, 112`).

**Überflüssiges**

16. `Rewards.swift`/`SyncMerge.swift`: `RewardSyncChoice`/`RewardSyncData` und `SyncPayload` sind getrennte Protokoll-Pfade (`SyncValidatable`) mit eigener Merge-Logik. Gewollt, aber `StoreSyncCoordinator` ist nur für die drei Fortschritts-Stores bequem nutzbar (Extension nur für `SyncState`/`SyncPayload`, `CloudSync.swift:126`).
17. Duplikat-Dateien im Arbeitsverzeichnis (`FiSiTrainer 3.xcodeproj/`, `RewardSyncTests 2.swift`) sind Betriebsmüll, ungetrackt. Hier nicht anfassen (Auftrag).

**Sonderfälle**

- `GameStore`: `speedBonusTotal` ist `Int?` nur für Altspielstände, `?? 0` an mehreren Stellen (`GameStore.swift:92`, `SubnetTrainer.swift:119`, `SubnetTrainer.swift:492`); `ExamStore` nutzt dagegen `Int`. Eine Form pro Altlast.
- `isLesson: Bool?`, `retryAppended` als Flags in der Session (`ExamStore.swift:23, 197`).
- `CloudSync.swift:93`: `Task.sleep` als Drosselung, `try?` beim Dekodieren (Zeile 102) und Kodieren (Zeile 117) verschluckt Fehler, ein defektes Cloud-Paket wird stumm ignoriert.
- Tests: keine `XCTSkip`, keine `sleep`, keine deaktivierten Tests gefunden.

## Lösungen (nach Nutzen/Risiko sortiert)

**L1: Gemeinsame Speicher-Schicht `JSONFileStore`** (behebt 1, 2, 9)
Eine kleine Struktur für Laden, Speichern, Beschädigungs-Sicherung und `maySave`/`saveError`. Alle fünf Stores nutzen sie. LearnPath bekommt dabei den korrekten Fehlerzweig.
- Nutzen: hoch (Datenverlust-Regel an einer Stelle). Risiko: mittel (Persistenz, Altspielstände müssen lesbar bleiben).
- Tests: bestehende Store-Tests, neu: Beschädigung je Store, fehlgeschlagene Sicherung. Sichtbar: nein.

**L2: LearnPath-Sync und Lektionsstand speichern** (behebt 4, 8)
LearnPath in die Sync-Verdrahtung aufnehmen (Zusammenführen: Tage vereinigen, Ziel letzte Änderung, Meilensteine vereinigen) und die laufende Lektion (`pending`) mitspeichern. Vorher klären, ob das gewünscht ist (Konzept `DUOLINGO-KONZEPT.md`).
- Nutzen: hoch bei Nutzung auf zwei Geräten. Risiko: mittel. Tests: `LearnPathTests`, `StoreSyncTests`. Sichtbar: ja (Streak folgt dem Konto).

**L3: Sync-Verdrahtung als Liste** (behebt 3, 4, 6)
Gemeinsames Protokoll `SyncableStore` (key, enable, disable) und eine Liste in `SyncController` statt vier benannter Eigenschaften; `combinedXP` nur an einer Stelle (im `RewardStore` oder einem kleinen `XPLedger`).
- Nutzen: mittel. Risiko: klein bis mittel. Tests: `StoreSyncTests`, `RewardSyncTests`. Sichtbar: nein.

**L4: XP- und Tempo-Regeln als eine Funktion** (behebt 5 und die Optional-Altlast)
`ScoringRules.award(correct:bonus:)` plus gemeinsame Prüfung für `speedBonusTotal`. Die drei Stores rufen sie auf.
- Nutzen: mittel (Regeln wie „Falsch ohne Bonus“ an einer Stelle). Risiko: klein. Tests: je Store XP-Tests bleiben unverändert grün. Sichtbar: nein.

**L5: Modus-Eigenschaften in `ExamMode`** (behebt 10, 11, 14)
Statt `mode == .exam`: Eigenschaften wie `usesTopic`, `showsResolutionAfterAnswer`, `advancesAutomatically`, `isGraded`; `calc`-Anzeige hängt an `ExamTask.Kind`/neuer Art `number`. `isLesson` wird zu `enum SessionPurpose { normal, lesson, review }` (Decoder bleibt kompatibel).
- Nutzen: mittel. Risiko: mittel (Session-JSON, Views). Tests: `ExamStoreTests`, Views per Simulator prüfen. Sichtbar: nein.

**L6: Aufgabentyp-Tabelle** (behebt 12, 13)
Je `ExamCard`-Fall eine kleine Struktur (`id`, `topic`, `mode`) statt langer Tupel-`switch`, damit `ExamCard.id`/`topic` und `cards(for:)` aus einer Zuordnung kommen. Nur wenn ein achter Aufgabentyp geplant ist; ansonsten bleibt es wie es ist.
- Nutzen: klein bis mittel. Risiko: mittel (Katalogdaten dürfen nicht angefasst werden müssen: Enum-Fälle bleiben). Tests: `ExamCatalogTests`. Sichtbar: nein.

**L7: Fehler im Sync sichtbar machen** (behebt `CloudSync.swift:102/117`)
Defekte Cloud-Pakete nicht stumm verwerfen, sondern in `SyncController` als Status anzeigen (Protokollzeile in den Einstellungen).
- Nutzen: klein bis mittel. Risiko: klein. Tests: `StoreSyncTests`. Sichtbar: ja (kleine Anzeige).

**L8: `ContentView.swift` nach Seiten teilen** (behebt 15)
Dashboard, Level-Ansicht, Spielseiten je eigene Datei; Seiten-Gruppen (`isPractice`, `showsCompanion`) als Eigenschaften von `LabPage`. Wegen des Stack-Limits nur dateiweise verschieben, keine neue Generik.
- Nutzen: mittel (meistgeänderte Datei). Risiko: klein (reines Verschieben), aber `project.yml`/`pbxproj` anpassen (Hinweis in STATUS.md zu `xcodegen`). Sichtbar: nein.

## Später (nicht als Karte)

- 7 (Lernschlüssel als Konvention) lässt sich mit L4 mitlösen.
- 16 (`StoreSyncCoordinator` nur für Fortschritts-Stores) erst, wenn L2/L3 anstehen.
- Aufräumen der ungetrackten Duplikate (17) macht Lino selbst.

## Empfohlene Reihenfolge

L1, L4, L3, L7, L2 (nach Rückfrage), L8, L5, L6. Je Karte: Branch, zuerst Tests für das bestehende Verhalten, dann Umbau, volle Suite, `--no-ff`-Merge.
