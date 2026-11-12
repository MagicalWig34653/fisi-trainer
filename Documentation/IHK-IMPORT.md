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
| AP2 Winter 2025/26 | Downloads | GA1, GA2, WiSo | 0 | offen, OCR liegt vor |
| AP2 Sommer 2025 | Downloads | GA1, GA2, WiSo | 0 | offen, OCR liegt vor |
| AP2 Winter 2024/25 | Downloads | GA1, GA2, WiSo | 0 | offen, Lösungen von GA1/GA2 brauchen OCR |

Rest von Etappe 1: 3 Termine à ca. 80 Karten. Schätzung: je Termin etwa so viel Aufwand wie Sommer 2026. Danach Etappen zu je 4 Termine rückwärts (Sommer 2024, Winter 2023, Sommer 2023, Winter 2022 usw.), alte AO und iCloud zuletzt.

## Abgleich mit dem Bestand

- sys-k01..k23 (`ExamCatalogIT.swift`) tragen nur "Termin und Aufgabe nicht erkennbar". Neue Karten wurden bei Themengleichheit (RAID, USV, Akku) nicht als Dublette gewertet, weil kein identischer Prüfungstext gefunden wurde. Offen: systematischer Textabgleich mit allen Terminen; bei Treffer die Bestandskarte auf Originalwortlaut umstellen und Quelle ergänzen (ID bleibt).
- Zwischen Downloads und iCloud überschneiden sich die Termine nicht (iCloud endet 2020/21, Downloads beginnt Winter 2021).

## Themenraster neuer AP2-Katalog (ab 2025)

Die Podcast-Seite (Folge 191) behandelt nur den Katalog Anwendungsentwicklung; für FiSi wurde das Raster aus dem IHK-Leitfaden AO 2020 verwendet: Konzeption und Administration (Systeme planen/konfigurieren, administrieren/betreiben, Speicher, Automatisierung/Skripte), Netzwerke (Protokolle, Komponenten, Netzsicherheit, Monitoring), WiSo.
Bestand deckt: Netze/Sicherheit/Systeme-Themen aus GA1 und GA2 2026 sowie Winter 2019/20. Fehlt noch: Automatisierungsskripte (Shell/PowerShell) und Containerisierung/Cloud in eigenen Karten.
Markierung "alter Katalog": Aufgaben vor Winter 2021 (alte AO) sind über `ExamOrigin.ordinance == .alt` erkennbar ("alte AO" in der Herkunftszeile). Themen, die nur im alten Katalog vorkamen (Blade-Server, USV-Kennlinien VFD/VI/VFI, Load Balancing in Winter 2019/20), bleiben erhalten und gelten als alter Katalog.

## Metadaten und Filter

Herkunft steckt in der Karten-ID `ihk-<ap1|ap2>-<jahr><s|w>-<ga1|ga2|wiso>-<aufgabe>` (`ExamOrigin`); eigene Aufgaben haben keine. Filter (`ExamOriginFilter`): nur aktuelle (4 Jahre), AP1/AP2, gespeichert in UserDefaults; Herkunftszeile über jeder Frage (Quiz und Lernpfad nutzen dieselbe Ansicht).
