# IHK-Prüfungsarchiv: Inventar, Abgleich, Fortschritt

Stand: 12.11.2026, Branch `agent/duolingo`. Quellen werden nur gelesen; PDFs und OCR-Texte liegen nicht im Repo.

## Quellen

| Quelle | Inhalt | Form |
|---|---|---|
| Downloads-Repo `IHK-Abschlusspruefungen-AP2-FiSi-AO2020-main` (hat Vorrang) | AO 2020, AP2 FiSi, Winter 2021 bis Sommer 2026 (10 Termine: GA1, GA2, WiSo, Lösungen) | Aufgaben meist Scans, Musterlösungen meist Text (inoffiziell, "zum Gegenlesen") |
| iCloud `Schule/BBS/Abschlussprüfung` | 41 Terminordner, 2000/01 bis Sommer 2025 (Sommer 2025 nur teilweise) | fast nur Scans (Textlage nur in einzelnen Terminen), ZPA-Lösungshinweise amtlich ("laut Lösungshinweis") |

Texterkennung: Apple Vision lokal (kein Kontingent). Handschriftliche Notizen werden ignoriert, Abbildungen als gekennzeichnete Textbeschreibung.

## Inventar iCloud (Dateien je Termin, davon mit Textlage)

2000/01 W 2 (1) · 2001/02 W 9 (0) · 2002 S 10 (0) · 2002/03 W 10 (0) · 2003 S 14 (0) · 2003/04 W 12 (0) · 2004 S 14 (0) · 2004/05 W 14 (0) · 2005 S 14 (0) · 2005/06 W 14 (0) · 2006 S 14 (0) · 2006/07 W 14 (0) · 2007 S 14 (0) · 2007/08 W 14 (12) · 2008 S 14 (0) · 2008/09 W 14 (13) · 2009 S 13 (0) · 2009/10 W 12 (0) · 2010 S 14 (0) · 2010/11 W 14 (2) · 2011 S 14 (0) · 2011/12 W 14 (0) · 2012 S 14 (0) · 2012/13 W 14 (0) · 2013 S 14 (1) · 2013/14 W 12 (0) · 2014 S 14 (0) · 2014/15 W 14 (0) · 2015 S 14 (0) · 2015/16 W 14 (1) · 2016 S 14 (7) · 2016/17 W 14 (7) · 2017 S 15 (7) · 2017/18 W 14 (7) · 2018 S 15 (8) · 2018/19 W 14 (1) · 2019 S 15 (8) · 2019/20 W 15 (8) · 2020 S 6 (2) · 2020/21 W 2 (1) · 2025 S 8 (0).
Teile: GA1 (FISI), GA2 (gemeinsam), WiSo, je mit Lösung. Es gibt keine iCloud-Dateien zu Winter 2021 bis Winter 2024 und zu 2025 Winter/2026; dort gilt das Downloads-Repo.

## Stand Import

| Termin | Quelle | Teile | Karten | Status |
|---|---|---|---|---|
| AP2 Sommer 2026 | Downloads | GA1 (21), GA2 (ca. 31), WiSo (30) | ca. 82 | fertig, committed |
| AP2 Winter 2019/20 | iCloud (Lösungshinweise amtlich) | GA1 (27), WiSo (30) | 57 | fertig, committed (nicht Teil der Etappe 1, aber bereits erfasst) |
| AP2 Winter 2025/26 | Downloads (Musterlösung inoffiziell, zum Gegenlesen) | GA1 (21), GA2 (26), WiSo (28) | 75 | fertig, committed (`ExamCatalogIHK2025W.swift`); WiSo 29 und 30 sind Dubletten von Sommer 2026 WiSo 21 und 24 und nicht doppelt angelegt |
| AP2 Sommer 2025 | Downloads (Musterlösung inoffiziell, zum Gegenlesen) | GA1 (20), GA2 (28), WiSo (19) | 67 | fertig, committed (`ExamCatalogIHK2025S.swift`); WiSo 6, 9, 11, 12, 17, 19, 20, 24 sind Dubletten von Winter 2025/26, WiSo 25 von Winter 2019/20; WiSo 28 und 30 nur Abbildungen |
| AP2 Winter 2024/25 | Downloads (Musterlösung inoffiziell, zum Gegenlesen) | GA1 (21), GA2 (29), WiSo (24) | 74 | fertig, committed (`ExamCatalogIHK2024W.swift`); WiSo 23 bis 28 sind Dubletten von Sommer 2026 (WiSo 19 bis 24) |
| AP2 Sommer 2024 | Downloads (Musterlösung inoffiziell, zum Gegenlesen; WiSo: vorläufiges Lösungsblatt) | GA1 (21), GA2 (28), WiSo (29) | 78 | fertig, committed (`ExamCatalogIHK2024S.swift`); WiSo 10 ist Dublette von Winter 2019/20 WiSo 9 |
| AP2 Winter 2023/24 | Downloads (Scans; Musterlösung inoffiziell, zum Gegenlesen; WiSo: vorläufiges Lösungsblatt) | GA1 (17), GA2 (28), WiSo (31) | 76 | fertig, committed (`ExamCatalogIHK2023W.swift`); keine Dublette |

Etappe 1 (Winter 2025/26, Sommer 2025, Winter 2024/25) ist fertig. Etappe 2 (laufend): Sommer 2024, Winter 2023/24, Sommer 2023, Winter 2022/23. Schätzung: je Termin etwa so viel Aufwand wie Winter 2024/25 (komplett OCR). Danach weitere Etappen zu je 4 Termine rückwärts (Sommer 2024, Winter 2023, Sommer 2023, Winter 2022 usw.), alte AO und iCloud zuletzt.

## Abgleich mit dem Bestand

- sys-k01..k23 (`ExamCatalogIT.swift`) tragen nur "Termin und Aufgabe nicht erkennbar". Neue Karten wurden bei Themengleichheit (RAID, USV, Akku) nicht als Dublette gewertet, weil kein identischer Prüfungstext gefunden wurde. Offen: systematischer Textabgleich mit allen Terminen; bei Treffer die Bestandskarte auf Originalwortlaut umstellen und Quelle ergänzen (ID bleibt).
- Systematischer Textabgleich (seit Winter 2025/26): Jede neue Termindatei wird vor dem Commit per 4-Wort-Shingles gegen alle Karten aller `ExamCatalog*.swift` (eigene Karten, sys-k01..k23, alle IHK-Termine) geprüft; Treffer ab 20 % Überdeckung werden von Hand gesichtet. Winter 2025/26: keine Treffer bei GA1/GA2 und sys-k; WiSo 29 (Emissionen im Lager) und 30 („Blauer Engel“) wörtlich wie Sommer 2026 WiSo 21 und 24, daher nicht angelegt.
- Unsichere OCR-Stellen Winter 2025/26 (in der Erklärung der Karte gekennzeichnet): GA1 1aa Spalten der Systemtabelle, 1ac/1c Abbildungen nur als Text, 3aa Zeilennummern 7 bis 11, 3ab Symbole && und || ergänzt; GA2 Netzwerkplan (Schnittstellennamen Router Reisebüro, Latenzspalte der Anbietertabelle); WiSo 6 Ende von Ziffer 4. Sachliche Unstimmigkeiten der Musterlösung (GA2 4ba: Formel ergibt für alle vier Anbieter über 99,9 %; WiSo 3 Zeugnis „auf Wunsch“) sind in der Erklärung vermerkt. GA1 2b: Musterlösung nennt nur Punkte, Lösung selbst erstellt.
- Sommer 2025: Textabgleich ergab acht WiSo-Aufgaben, die (fast) wörtlich in Winter 2025/26 wiederkehren, und eine aus Winter 2019/20; nicht angelegt, Kommentar in der Datei. Thematisch ähnliche, aber anders gestellte Aufgaben (WiSo 13, 14, 16, 18, 21, 23) sind angelegt. Unstimmigkeit der Musterlösung: GA1 4aa nennt „40 1 42 2 …“, nach dem Programmentwurf (i beginnt bei 0) ist es „40 0 42 1 …“; in der Karte vermerkt. GA2 Netzwerkplan als Textbeschreibung, MQTT-Abbildung (4c) nicht übernommen. Die PDFs hatten bei GA1/GA2 eine saubere Textlage, nur WiSo brauchte OCR.
- Winter 2024/25: Alle PDFs (auch die Musterlösungen) waren Scans, alles per OCR (Apple Vision). WiSo 23 bis 28 kehren aus Sommer 2026 wieder und sind nicht angelegt. WiSo 14 ähnelt Winter 2025/26 WiSo 24 (Organigramm, Stabsstelle), hat aber eigene Abteilungen und Optionen und ist angelegt. Unsichere Stellen, in den Karten vermerkt: GA2 2ba Subnetzmaske im Scan „255.209.0.0“ (gemeint 255.255.0.0); GA2 3d A-Eintrag „03.0.113.21“ (vermutlich 203.0.113.21); WiSo 4 Ziffer 2 endet im Scan abgeschnitten; Organigramm WiSo 13/14 nur grob als Text. Unstimmigkeiten im Original: GA2 Netzskizze nennt 43.217.89.121/30, Aufgabe 2c 203.0.113.121/30; Musterlösung GA1 4ab nennt „Zeile 8“ statt Zeile 9 und „[i-0]“ statt i-1; GA1 3ab fragt nach GiB, die Musterlösung rechnet in TiB; GA1 3c rundet 12,704 TiB auf 12,8 TiB auf. GA1 4aa (Werte nach Programmlauf) ist selbst ermittelt, weil die Musterlösung nur die Punkte nennt.
- Sommer 2024: GA1, GA2 und WiSo hatten eine (doppelte, unsaubere) Textlage; erfasst wurde trotzdem per Apple-Vision-OCR, Tabellen und Abbildungen über gerenderte Seiten geprüft. Textabgleich: WiSo 10 (Arbeitsschutzausschuss) fast wörtlich wie Winter 2019/20 WiSo 9, nicht angelegt; GA1 4a (User/Device CALs) ähnelt Sommer 2025 GA1 3b, hat aber eigenen Text und ist angelegt. Unsichere Stellen, in den Karten vermerkt: GA1 2b Mailbild (Zuordnung angezeigte URL/Tooltip erschlossen); GA2 2c Bildschirmausschnitt des Mailclients teils unleserlich; GA2 4c Vorzeichen bei „blau -83 dBm“ schwach; GA2 Netzwerkplan als Text. Auffälligkeiten im Original: GA2 3 Einleitungssatz endet ohne „soll“; GA2 1bb Musterlösung lässt TTL 127 und Prüfsumme 0 stehen; WiSo 15 Spalte „Gesellschafter“ im Registerauszug; WiSo 22 fragt nach „anmeldepflichtigem“ Kartell (Anmeldepflicht seit 2005 abgeschafft); Tippfehler im Original („mer“, „Softeware“, „der der“, „Ecotech“) übernommen. GA1 2aa und WiSo-Zuordnungen mit doppelten Zielen sind auf eindeutige Paare gekürzt, die übrigen stehen in der Erklärung.
- Winter 2023/24: Aufgaben sind Scans (Apple-Vision-OCR), die Musterlösungen haben eine Textlage; das WiSo-Lösungsblatt wurde als Bild gelesen. Textabgleich ohne Dublette; ähnlich, aber angelegt: WiSo 17 (Kündigungsschutz, andere richtige Antwort als Sommer 2024 WiSo 23), WiSo 20 (Wirtschaftlichkeit, andere Zahlen als Sommer 2024 WiSo 20), WiSo 22 (Businessplan, andere richtige Aussage als Sommer 2024 WiSo 19), GA2 3ba (VLAN-Gründe, anderer Kontext als Winter 2025/26 GA2 3aa). Unsichere Stellen, in den Karten vermerkt: GA1 2c Rechtestring („----rw-r--“, am Bild geprüft); GA1 4e Textende („price.“) verrauscht; GA2 Netzwerkplan, Routingtabelle und Wireshark-Trace als Text; WiSo 20 Tabellenkopf „3“ fehlt in der OCR. Auffälligkeiten im Original: GA1 3a Musterlösung deklariert „int sumLast“ mehrfach (Compilerfehler in C#); GA2 1aa Musterlösung schreibt „10.2.2.0“ statt Next-Hop 10.2.2.2; WiSo 26 Urabstimmung/Streik vor der Schlichtung; Tippfehler übernommen („Gehaltvorstellung“, „einem Mitarbeiter die“, „von Herr Räwer“, „vier durchgeführten Aufträge“). WiSo 4 ist in 4a und 4b geteilt.
- Zwischen Downloads und iCloud überschneiden sich die Termine nicht (iCloud endet 2020/21, Downloads beginnt Winter 2021).
- Die oben genannten Vermerke „in den Karten“ stehen dort seit dem 12.11.2026 nicht mehr als Arbeitsnotiz: Lesbare Stellen gelten wie im Original, unsichere Stellen tragen im Aufgabentext „[sinngemäß ergänzt]“, Abweichungen der Musterlösung stehen als neutraler „Hinweis:“ in der Erklärung.

## Gegenlesen (12.11.2026)

Die Lösungen aller bis dahin importierten Termine (Winter 2019/20, Winter 2023/24 bis Sommer 2026) und der Übungskarten sys-k01..k23 wurden am 12.11.2026 gegengelesen: zwei unabhängige Prüfberichte (Claude und Codex), danach ein Schiedsspruch, bei dem jeder Befund gegen das Original (Seiten als Bild) geprüft und jede Rechnung nachgerechnet wurde. Ergebnis: 16 Karten korrigiert, 7 bestätigt, eine Entscheidung durch Lino (2025W GA2 4ba: IHK-Lösung gewertet, Hinweis auf 99,99 %).

## Formulierungsregel für Lerntexte (verbindlich für alle künftigen Etappen)

1. **Präfixe:** Lösungen aus Musterlösungen beginnen mit „Lösung laut IHK-Musterlösung:“, aus WiSo-Lösungsblättern mit „Lösung laut Lösungsblatt:“, aus offiziellen Lösungshinweisen mit „Lösung laut Lösungshinweis:“, eigene Lösungen (sys-k) mit „Lösung:“. „Inoffiziell“ steht höchstens einmal in der Quellenangabe, nicht in jeder Erklärung.
2. **Keine Arbeitsnotizen:** „zum Gegenlesen“, „im Scan“, „OCR“, „unlesbar“, „erschlossen“, „vermutlich“ und Ähnliches gehören nicht in Aufgaben-, Options- oder Erklärungstexte. Lernende kennen den Scan nicht.
3. **Unsichere Lesart:** erst das Original als Bild ansehen. Ist die Stelle lesbar, gilt der Originaltext ohne Notiz. Ist sie wirklich unlesbar, steht im Aufgabentext „[sinngemäß ergänzt]“ und in der Erklärung nichts.
4. **Abweichungen von der Musterlösung** als Lernhinweis: „Hinweis: Die Musterlösung nennt X; fachlich genauer ist Y, weil …“ bzw. „Hinweis: Im Original steht X (Druckfehler); gemeint ist Y.“ Keine Spekulation über Absichten der IHK.
5. **Ergebnis vorn:** Die gewertete Lösung steht im ersten Satz, ein Hinweis höchstens am Ende und in höchstens zwei Sätzen.
6. **Zusatzinfos ohne Fehlerbezug** (z. B. MTU + 28 Byte) bleiben, eingeleitet mit „Hinweis:“.

Der Test `ExamTextHygieneTests` sucht in allen Karten nach „Gegenlesen“, „Scan“, „OCR“ und „vermutlich“ und schlägt bei einem Treffer fehl. Ausgenommen sind Fachwörter, in denen „scan“ nur Wortteil ist (Portscan, Virenscanner), sowie „WLAN-Scan“ (Aufgabentext 2024S GA2 4c).

## Themenraster neuer AP2-Katalog (ab 2025)

Die Podcast-Seite (Folge 191) behandelt nur den Katalog Anwendungsentwicklung; für FiSi wurde das Raster aus dem IHK-Leitfaden AO 2020 verwendet: Konzeption und Administration (Systeme planen/konfigurieren, administrieren/betreiben, Speicher, Automatisierung/Skripte), Netzwerke (Protokolle, Komponenten, Netzsicherheit, Monitoring), WiSo.
Bestand deckt: Netze/Sicherheit/Systeme-Themen aus GA1 und GA2 2026 sowie Winter 2019/20. Fehlt noch: Automatisierungsskripte (Shell/PowerShell) und Containerisierung/Cloud in eigenen Karten.
Markierung "alter Katalog": Aufgaben vor Winter 2021 (alte AO) sind über `ExamOrigin.ordinance == .alt` erkennbar ("alte AO" in der Herkunftszeile). Themen, die nur im alten Katalog vorkamen (Blade-Server, USV-Kennlinien VFD/VI/VFI, Load Balancing in Winter 2019/20), bleiben erhalten und gelten als alter Katalog.

## Metadaten und Filter

Herkunft steckt in der Karten-ID `ihk-<ap1|ap2>-<jahr><s|w>-<ga1|ga2|wiso>-<aufgabe>` (`ExamOrigin`); eigene Aufgaben haben keine. Filter (`ExamOriginFilter`): nur aktuelle (4 Jahre), AP1/AP2, gespeichert in UserDefaults; Herkunftszeile über jeder Frage (Quiz und Lernpfad nutzen dieselbe Ansicht).
