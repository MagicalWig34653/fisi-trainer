# Duolingo-Prinzip für den FiSi Trainer

Stand: 2026-11-12. Auftrag: „Den FiSi Trainer ausbauen, das soll ein bisschen wie Duolingo werden.“ Das Konzept beschreibt, was die App schon hat, was zum Duolingo-Prinzip fehlt und in welchen Wellen es entsteht. Die Karten dazu stehen im Todolino-Projekt „FiSi Trainer“ (Schlüssel `fisi/duo/...`).

## 1. Was die App schon hat

| Baustein | Stand |
| --- | --- |
| Kurze Runden | Ja: 5 bis 15 Aufgaben je Runde (Prüfungsquiz 10, Richtig/Falsch 15, Zuordnen 6 ...) |
| Sofortiges Feedback mit Erklärung | Ja, nach jeder Antwort (außer in der Prüfungssimulation) |
| Aufgabentypen | Einzelauswahl, Mehrfachauswahl, Zuordnen, Reihenfolge, Lückentext (als Zuordnung), Wahr/Falsch, Fakten, 21 Rechengeneratoren (alle als Auswahl) |
| XP und Level | Ja: XP je Spiel, gemeinsame Roadmap mit 100 Leveln (`RewardStore`, Höchststand) |
| Belohnungen, Haustier | Ja: drei SceneKit-Haustiere, Ausstattung, Bindung, Begleiter während der Übung |
| Adaptives Lernen | Ja: `AdaptiveLearning` gewichtet Karten nach bisherigen Fehlern (keine festen Wiederholungsintervalle) |
| Persistenz, iCloud-Sync | Ja, lokal, optional iCloud |

## 2. Was zum Duolingo-Prinzip fehlt

| Baustein | Lücke | Entscheidung |
| --- | --- | --- |
| Lernpfad mit Einheiten und Lektionen | Es gibt nur einen Spielehub, keine geführte Reihenfolge und keinen sichtbaren Fortschritt je Thema | Welle 1 |
| Tagesziel und Streak | Gibt es nicht (der „streak“ im Code ist die Serie richtiger Antworten in einer Runde) | Welle 1 |
| Streak-Schutz | fehlt | Welle 2 |
| Erinnerungen | keine lokalen Notifications | Welle 2 |
| Wiederholung schwacher Aufgaben | Gewichtung vorhanden, aber keine fälligen Wiederholungen nach Intervall und kein eigener Einstieg | Welle 3 |
| Aufgabentypen | Rechnen nur per Auswahl, Lückentext nur per Zuordnungsliste | Welle 4 |
| Haustier an Streak/Tagesziel koppeln | fehlt | Welle 5 |
| Herzen | bewusst nicht (Empfehlung) | siehe Fragen |
| Ligen, Freundeslisten | bewusst nicht: Single-User, kein Backend, keine Konten (AGENTS.md) | verworfen |
| Lernpfad nach Lernfeldern | nur bei Bedarf, Karten sind nach Themen sortiert | siehe Fragen |

## 3. Zielbild

Der Start der App zeigt oben Streak, Tagesziel-Ring und XP, darunter den Lernpfad. Der Pfad hat zwei Abschnitte (WiSo, IT). Jedes der 12 Themen ist eine Einheit mit fünf Lektionsknoten. Eine Lektion ist eine Runde mit 10 Aufgaben (3 bis 5 Minuten) mit Feedback und Erklärung nach jeder Antwort. Lektionen eines Themas werden nacheinander freigeschaltet. Jede XP aus jedem Spiel zählt zum Tagesziel. Wer das Ziel erreicht, hält den Streak; ein Streak-Schutz überbrückt einen verpassten Tag.

## 4. Designentscheidungen

Offene Fragen sind als `ask_question` an Lino gestellt (Karte `fisi/duo`). Bis zur Antwort gilt die Empfehlung.

1. **Struktur des Pfads.** Empfehlung: nach Prüfungsbereichen (Fach, dann Thema), Themen frei wählbar, Lektionen eines Themas nacheinander. Alternativen: strikt linear; nach Lernfeldern des Rahmenplans.
2. **Herzen.** Empfehlung: nein. Die App hat keine Monetarisierung, und ein Fehler-Limit frustriert bei der Prüfungsvorbereitung. Stattdessen sollen falsch beantwortete Aufgaben am Ende der Lektion nochmal kommen (Welle 3).
3. **Tagesziel.** Empfehlung: 100 XP als Standard (ca. eine Lektion), später wählbar: Locker 50, Normal 100, Intensiv 200.
4. **XP.** Bestehende XP-Regeln bleiben (25 je richtig plus Tempobonus, 5 je falsch, 50 Rundenbonus). Eine Lektion bringt damit grob 60 bis 300 XP.
5. **Streak-Regel.** Ein Tag zählt, wenn die Tages-XP das Tagesziel erreichen. Tageswechsel nach lokalem Kalender. Streak-Schutz (max. 2) wird nach 7 Tagen Streak verdient und überbrückt genau einen verpassten Tag.

## 5. Wellen

### Welle 1: Kern (in diesem Zug umgesetzt)

- `LearnPathStore` (`learnpath-progress.json`): fertige Lektionen je Thema, Tages-XP je Kalendertag, Streak, Streak-Schutz, Tagesziel. Reine Rechenlogik in `LearnPathProgress` mit übergebenem Datum und Kalender (testbar).
- Lernpfad-Ansicht oben auf der Übersicht (`LearnPathView`), Mac und iPhone.
- Lektionsstart startet eine Runde im Modus Prüfungsquiz (`ExamStore.start(mode: .quiz, topic:)`); die vorhandene Aufgabenansicht, Erklärungen, Haptik und Begleiter bleiben. Nach Abschluss wird die Lektion als fertig gewertet.
- XP-Zuwachs aller Spiele fließt in die Tages-XP (Delta der Summen-XP, wie bei `RewardStore`).

Bewusste Vereinfachung in Welle 1: Die Lektion ist eine adaptiv gewichtete Zufallsrunde aus dem Thema, kein fest zusammengestellter Lehrtext. Der Streak-Schutz wird in der Logik gezählt und angezeigt; das Verdienen ist in Welle 1 schon enthalten, die Erklärung im UI kommt in Welle 2.

### Welle 2: Streak-Schutz, Tagesziel wählbar, Erinnerungen

Einstellung des Tagesziels, Erklärtext zum Schutz, lokale Erinnerung (Opt-in, Uhrzeit, nicht senden wenn Ziel erreicht).

### Welle 3: Wiederholung

Fällige Karten nach Intervallen (1, 3, 7, 21 Tage) aus `AdaptiveLearning`/`LearningRecord`, eigener „Wiederholen“-Knoten im Pfad, Fehler am Lektionsende nochmal stellen.

Umgesetzt (12.11.): `LearningRecord` trägt `box` (0 bis 3) und `lastSeen` (optional, alte Spielstände bleiben lesbar). Richtig steigert die Stufe (Abstand 3, 7, 21 Tage), falsch setzt sie auf 0 (1 Tag). `ExamStore.dueCards(subject:)` liefert fällige Quiz-Karten (ohne Zeitstempel nur bei Übungsbedarf), `startReview(subject:)` startet daraus eine Runde (bis 10 Aufgaben, Fehler am Ende nochmal, zählt nicht als Lektion). Im Pfad erscheint je Fach eine Zeile „Wiederholen“ nur, wenn etwas fällig ist. Die Fehlerwiederholung am Lektionsende stammt aus Welle 1. Nur Auswahlkarten (Prüfungsquiz); andere Kartentypen folgen bei Bedarf.

### Welle 4: Aufgabentypen

Numerische Eingabe bei Rechenaufgaben (Toleranz, Einheit), Lückentext mit Wortbank im Satz.

### Welle 5: Haustier und Belohnungen

Haustier reagiert auf Tagesziel und Streak-Meilensteine, Wochenkalender, Meilensteine 7/30/100 Tage, Bindungspunkte.

## 6. Risiken

- `ContentView.swift` ist groß; neue Ansichten in eigene Dateien auslagern und über `LazyPage`/`AnyView`-Grenzen einbinden (Stack-Limit iOS, siehe STATUS.md).
- Neue Quelldateien müssen von Hand in `project.pbxproj` eingetragen werden (XcodeGen-Testhost-Problem, siehe STATUS.md).
- Lektionen und iCloud-Sync: Der Lernpfad-Stand wird in Welle 1 nicht synchronisiert (lokal). Die XP selbst werden wie bisher synchronisiert.
