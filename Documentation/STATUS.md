# Arbeitsstand und Übergabe

Stand: 2026-10-17, `main` bei Merge von PR 17. Dieses Dokument ist für die nächste Session gedacht: was ist fertig, was ist offen, was ist bekannt. Die Entwicklung läuft ab jetzt **lokal in Xcode auf dem Mac des Projektinhabers**; die bisherigen Sessions liefen in einer Cloud-Umgebung ohne Swift-Compiler (siehe „Erfahrungen aus den Cloud-Sessions“).

## Fertig und auf `main`

- **iOS/iPadOS-Version** (eine Multiplattform-Target, macOS 14 / iOS 17): native `TabView` mit vier Tabs (`MobileTab`: `dashboard`, `practice` = Übungen-Hub, `rewards`, `reference`), Mac und breites iPad behalten die Seitenleiste. Angeheftete Weiter-Schaltfläche (`FlowButton`/`PinnedAction`), Haustier als Sheet, Liquid Glass mit Fallback, Haptik, Seitenübergänge, native `NavigationStack` mit Zurückwischen. Details in `ARCHITECTURE.md`.
- **Releases:** v1.3.0 und v1.4.0 (nur macOS-DMG, ad-hoc signiert, nicht notarisiert). `main` enthält seitdem weitere Änderungen, die in keinem Release stecken (mobile UX, iCloud-Code, TestFlight-Skripte). Ein neues Release steht aus (Aufruf: Actions → *Release macOS app* → Run workflow, siehe `AGENTS.md`).
- **iCloud-Sync (Code komplett, noch nicht auf echten Geräten getestet):** `SyncMerge.swift` (reine Merge-Logik), `CloudSync.swift` (`SyncBackend`, `StoreSyncCoordinator`, `KeyValueSyncBackend`, `SyncController`), `SyncSettingsView.swift` (Schalter in der Level-Ansicht), `enableSync`/`disableSync` in den drei Stores. Tests: `SyncMergeTests`, `StoreSyncTests` (simuliertes iCloud). Konzept und Regeln: `ICLOUD-SYNC.md`.
  - Der Schalter existiert nur in Builds mit Compile-Flag `ICLOUD_SYNC` (gesetzt für `sdk=iphoneos*` in `project.yml`/pbxproj) und `FiSiTrainer-iOS.entitlements`. Simulator, CI und die ad-hoc signierte Mac-DMG haben beides nicht.
  - Synchronisiert werden XP, Lernstand und Prüfungsverlauf. **Nicht** synchronisiert: Haustier-Auswahl, Ausstattung, Spielzeug, Bindung (`RewardStore` bleibt pro Gerät; Belohnungen leiten sich aus der kombinierten XP ab).
- **TestFlight-Vorbereitung:** `Scripts/testflight-local.sh` (lokaler Xcode, Automatic Signing über den angemeldeten Account), `Packaging/ExportOptions-TestFlight.plist`, optionaler Workflow `testflight.yml`, Anleitung `TESTFLIGHT.md`. Das App-Icon (`AppIcon.icon`) gilt für alle Square-Plattformen.

## Zustand von TestFlight / Apple-Account

- Bezahlter Developer-Account vorhanden, Team-ID `J2DU2P47XW`, Bundle-ID `de.linolaske.fisitrainer`, App-Eintrag „FiSi Trainer“ in App Store Connect angelegt.
- Ein Lauf von `testflight.yml` mit einem API-Schlüssel der Rolle *App Manager* hat den Archive-Schritt erfolgreich beendet (inklusive iCloud-Entitlement), ist aber beim Export mit `Cloud signing permission error` gescheitert. Cloud-verwaltetes Signieren braucht die Rolle *Admin* (bei jedem Lauf, nicht nur einmalig).
- Deshalb der Plan: Upload lokal per `bash Scripts/testflight-local.sh`. **Das Skript wurde noch nie ausgeführt.** Der erste echte Lauf steht aus; mögliche Stolpersteine: Xcode-Account nicht angemeldet, iCloud-Fähigkeit der App-ID im Developer-Portal (Identifiers) noch nicht aktiv, interne Testgruppe in TestFlight fehlt.
- Im GitHub-Repo liegen die Secrets `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_P8` (App-Manager-Schlüssel). Das Repository ist **öffentlich**. Der Workflow startet nur manuell; Schlüssel nicht ändern, Workflow nicht starten, solange der Inhaber es nicht ausdrücklich will. Der App-Manager-Schlüssel kann widerrufen werden, sobald der lokale Weg läuft.

## Offene Aufgaben (Vorschlag zur Reihenfolge)

1. **Ersten TestFlight-Build lokal hochladen** und einer internen Testgruppe zuweisen.
2. **Zwei-Geräte-Test des iCloud-Syncs** (iPhone und iPad, dieselbe Apple-ID): Fortschritt auf Gerät A, erscheint auf B; paralleles Lernen; Reset auf einem Gerät; Schalter aus/an. Bei Erfolg README und Datenschutz-Aussage ergänzen („ohne Konto, lokal gespeichert“ gilt dann mit optionalem iCloud-Sync); vorher nicht bewerben.
3. **Belohnungen synchronisieren** (Haustier-Auswahl, Ausstattung, Spielzeug, Bindungszähler): Vorschlag in `ICLOUD-SYNC.md` (Last-Writer-Wins mit Zeitstempel bzw. Maximum bei Zählern), mit Tests; Schlüssel `sync.rewards` ist reserviert.
4. **Mac mit Developer ID signieren und notarisieren** (`Scripts/package-release.sh`: aktuell `CODE_SIGNING_ALLOWED=NO` und ad-hoc `codesign`; danach `notarytool`, Zertifikat und Profil). Erst damit kann die Mac-App iCloud nutzen; separate Mac-Entitlements mit `ubiquity-kvstore-identifier`, die ad-hoc `FiSiTrainer.entitlements` bleibt iCloud-frei. Danach `AGENTS.md`/README-Aussagen zur ad-hoc-Signatur anpassen.
5. **Neues Release** (v1.5.0) mit den seit v1.4.0 gemergten Änderungen; README-Beispiele und Download-Links prüfen.
6. Falls der App Store angestrebt wird: Datenschutztext, Screenshots, Altersfreigabe (bisher ausdrücklich „erstmal nicht im Store“).

## Hinweise für die Zusammenarbeit

- Der Projektinhaber hat erlaubt, eigene PRs zu mergen, sobald die CI (`test` und `ios-build`) grün ist. Releases/Tags nur auf Wunsch.
- Antworten und Doku auf Deutsch. Der Mac-Funktionsumfang darf durch mobile Änderungen nicht leiden.
- Die Bundle-ID wurde vom Inhaber auf `de.linolaske.fisitrainer` geändert (vorher `de.fisitrainer.mac`); Spielstände der alten ID sind für die neue App nicht lesbar. Das ist akzeptiert.

## Erfahrungen aus den Cloud-Sessions (Stolperfallen)

- **Kein Swift-Compiler in der Cloud-Umgebung.** Die CI war der einzige Compile-Check; Fehler kamen deshalb erst nach dem Push. Lokal vor jedem Push `xcodebuild test` (macOS) und den iOS-Simulator-Build ausführen (Befehle in `DEVELOPMENT.md`).
- **iOS-Hauptthread-Stack ist 1 MB.** Sehr tief verschachtelte generische SwiftUI-Typen führten beim Auflösen zu `EXC_BAD_ACCESS` (Stack Overflow) und schwarzem Bildschirm auf dem iPhone. Abhilfe: nicht-generische Grenzen (`LazyPage`/`AnyView` in `ContentView.swift`). Beim Erweitern der Hauptansicht darauf achten.
- **Private Hilfstypen:** `LabStyle` (ContentView) und `RewardStyle` (Rewards) sind `private`. Neue Dateien brauchen eigene Farben oder einen gemeinsam sichtbaren Stil.
- **Default-Argumente und Actor-Isolation:** Ein Standard-Closure, der einen `@MainActor`-Initializer aufruft, muss selbst `@MainActor` sein (`SyncController.makeBackend`).
- **Store-Tests:** Nach `answer(...)` ist `selectedAnswer` gesetzt; vor der nächsten Antwort muss `nextQuestion()` aufgerufen werden, sonst bleibt die XP gleich.
- **Neue Quelldateien:** `project.yml` anpassen und `xcodegen generate` ausführen. In den Cloud-Sessions wurde `project.pbxproj` von Hand ergänzt (kein XcodeGen verfügbar); wer lokal `xcodegen generate` ausführt, sollte das Ergebnis mit `git diff` auf unbeabsichtigte Änderungen prüfen (bedingte Einstellungen wie `CODE_SIGN_ENTITLEMENTS[sdk=iphoneos*]` und `SWIFT_ACTIVE_COMPILATION_CONDITIONS[sdk=iphoneos*]` müssen erhalten bleiben).
- **Tags:** Aus der Cloud-Umgebung ließ sich kein Tag pushen; Releases liefen über den manuellen Workflow `release.yml` (`workflow_dispatch`).
