// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Aufgaben früherer IHK-Abschlussprüfungen (Teil 2, Fachinformatiker Systemintegration) im
/// Originalwortlaut. Nur für den privaten Gebrauch des Projektinhabers (Entscheidung 2026-11-12);
/// vor einer Veröffentlichung oder Weitergabe müssen diese Karten entfernt oder umformuliert werden.
///
/// Regeln: Aufgabenstellung und Ausgangssituation unverändert übernehmen, Abbildungen als gekennzeichnete
/// Textbeschreibung, Antwortoptionen bei offenen Aufgaben sind ergänzt (die erste Option ist richtig).
/// Lösungen „laut Lösungshinweis“ stammen aus den offiziellen Lösungshinweisen des Archivs, alle anderen
/// aus inoffiziellen Musterlösungen; alle wurden am 12.11.2026 gegengelesen (Regeln: `Documentation/IHK-IMPORT.md`). Die Quelle steht am Ende jeder Erklärung. Fortschritt: `Documentation/IHK-IMPORT.md`.
extension ExamCatalog {
    static let ihk: [ExamCard] = ihkS2026 + ihkW2025 + ihkS2025 + ihkW2024 + ihkS2024 + ihkW2023 + ihkS2023 + ihkW2022 + ihkS2022 + ihkW2021 + ihkW1920GA1 + ihkW1920WiSo

    // MARK: - Hilfen für alle IHK-Karten

    /// Quellenzeile aus der Karten-ID (`ExamOrigin`).
    static func ihkSource(_ id: String) -> String {
        "Quelle: \(ExamOrigin(cardID: id)?.sourceText ?? id)."
    }

    /// WiSo-Erklärung „Ziffer N. …“ mit der gewerteten Antwort vorn, weil die App die Optionen mischt:
    /// „„Antwort“ (im Original Ziffer N). …“. Andere Erklärungen bleiben unverändert.
    static func ihkZiffer(_ explanation: String, answer: String) -> String {
        guard explanation.hasPrefix("Ziffer "), let dot = explanation.firstIndex(of: ".") else { return explanation }
        let number = explanation[explanation.index(explanation.startIndex, offsetBy: 7)..<dot]
        guard !number.isEmpty, number.allSatisfy(\.isNumber) else { return explanation }
        let rest = explanation[explanation.index(after: dot)...]
        let quoted = answer.hasPrefix("„") ? answer : "„\(answer.hasSuffix(".") ? String(answer.dropLast()) : answer)“"
        return "\(quoted) (im Original Ziffer \(number)).\(rest)"
    }

    private static func ihkPrompt(_ lage: String, _ prompt: String) -> String {
        lage.isEmpty ? prompt : "\(lage)\n\n\(prompt)"
    }

    /// Einfachauswahl; die erste Option ist richtig.
    static func ihkChoice(_ id: String, _ topic: ExamTopic, _ lage: String, _ prompt: String,
                          _ options: [String], _ explanation: String) -> ExamCard {
        .choice(id: id, topic: topic, prompt: ihkPrompt(lage, prompt), options: options,
                explanation: "\(explanation) \(ihkSource(id))")
    }

    static func ihkMultiple(_ id: String, _ topic: ExamTopic, _ lage: String, _ prompt: String,
                            correct: [String], wrong: [String], _ explanation: String) -> ExamCard {
        .multiple(id: id, topic: topic, prompt: ihkPrompt(lage, prompt), correct: correct, wrong: wrong,
                  explanation: "\(explanation) \(ihkSource(id))")
    }

    static func ihkMatch(_ id: String, _ topic: ExamTopic, _ lage: String, _ prompt: String,
                         pairs: [(String, String)], extra: [String], _ explanation: String) -> ExamCard {
        .match(id: id, topic: topic, prompt: ihkPrompt(lage, prompt), pairs: pairs, extra: extra,
               explanation: "\(explanation) \(ihkSource(id))")
    }

    static func ihkOrder(_ id: String, _ topic: ExamTopic, _ lage: String, _ prompt: String,
                         steps: [String], _ explanation: String) -> ExamCard {
        .order(id: id, topic: topic, prompt: ihkPrompt(lage, prompt), steps: steps,
               explanation: "\(explanation) \(ihkSource(id))")
    }

    // MARK: - Winter 2019/20, GA1 (Ganzheitliche Aufgabe I, Fachinformatiker Systemintegration)

    private static let w1920Lage = "Ausgangssituation (Handlungsschritte 1 bis 5): Sie sind bei Event GmbH in der IT-Abteilung beschäftigt. Die Event GmbH ist Dienstleister im Bereich der Planung und Durchführung von Fachmessen mit Schwerpunkt Smart Factory. Sie hat ihre Zentrale in Stuttgart.\nDie Event GmbH arbeitet im WAN-Bereich mit dem Internet-Provider iKomP zusammen.\nDie bestehende IT-Infrastruktur der Event GmbH soll technisch und organisatorisch aktualisiert werden. Dabei wird besonderer Wert auf die IT-Sicherheit gelegt.\nSie arbeiten in diesem Projekt mit."
    private static let w1920Einheiten = "Hinweis: Es werden die folgenden Einheiten verwendet: Speicherkapazität (z. B. Festplatten) in MiB/GiB/TiB (1.024 · 1.024 Byte); Transferrate (z. B. PCI-Bus) in MB/s (1.000 · 1.000 Byte/s); Transferrate (z. B. Ethernet, DSL) in Mbit/s (1.000 · 1.000 bit/s)."
    private static let w1920Plan = "[Abbildung als Text, Netzwerkplan der Event GmbH: Ein Gerät „Router / Firewall / VPN-Gateway“ verbindet drei Bereiche. Erstens das WAN (80.90.100.2/30) zum Internet; dort sitzt auch die Remote-Administration der IKomP AG. Zweitens die DMZ, ein Switch mit dem Webserver 192.168.250.1/29. Drittens das LAN: Die Router-Schnittstelle 172.16.31.1/30 ist mit Port 8 des Core-Switch (172.16.31.2/30) verbunden. Am Core-Switch hängen die Switches WS-01 bis WS-03 mit Clients (u. a. Verw-01, Verw-20, Verw-21, Entw-01, Entw-08, Entw-11, Admin-01) und Druckern sowie das SAN-System und der Server „DC und DNS“.]"
    private static let w1920Q = "IHK AP2 FiSi Winter 2019/20, GA1"

    static let ihkW1920GA1: [ExamCard] = [
        // 1. Handlungsschritt: Netzwerkstruktur analysieren, Routing einrichten
        .choice(id: "ihk-ap2-2019w-ga1-1aa", topic: .netze,
                prompt: "\(w1920Lage)\n\n1. Handlungsschritt (25 Punkte): Die Netzwerkstruktur analysieren und das Routing einrichten\na) Das Netzwerk der Event GmbH soll neu strukturiert werden.\naa) Die Administratoren wollen VLANs für die Abteilungen Verwaltung, Entwicklung und Management einrichten.\nErläutern Sie zwei Gründe, die für die Einrichtung von VLANs sprechen. (4 Punkte)",
                options: ["Begrenzung des Datenverkehrs durch kleinere Broadcastdomänen; höhere Sicherheit durch Zugriffsregeln zwischen den VLANs",
                          "Höhere Übertragungsrate je Verbindung, weil VLANs die Bandbreite der Kabel vergrößern; keine Router mehr nötig",
                          "Größere Broadcastdomänen für schnellere Namensauflösung; automatische Verschlüsselung des Verkehrs zwischen den Abteilungen",
                          "Wegfall der Subnetzmasken, weil jedes VLAN dieselbe IP-Adresse nutzt; geringerer Stromverbrauch der Switches",
                          "Gemeinsame MAC-Adressen für alle Abteilungen; Ersatz der Firewall durch VLAN-Tags"],
                explanation: "Lösung laut Lösungshinweis (u. a.): flexiblere Nutzung der physischen Infrastruktur, Begrenzung des Datenverkehrs durch kleinere Broadcastdomänen, Priorisierung von Datenverkehr (QoS, z. B. VoIP), erhöhte Sicherheit durch Zugriffsregeln zwischen den VLANs. Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe aa."),
        .choice(id: "ihk-ap2-2019w-ga1-1ab", topic: .netze,
                prompt: "\(w1920Lage)\n\n1. Handlungsschritt (25 Punkte)\nab) VLANs werden mit einem „Tag“ in Netzwerken identifiziert:\n[Abbildung als Text: Das Tag ist 32 Bit lang. Es besteht aus TPID (16 Bit) und TCI (16 Bit); die TCI setzt sich zusammen aus PCP (3 Bit), DEI (1 Bit) und VID (12 Bit).]\n– TPID – Tag Protocol Identifier: Fester Wert 8100hex\n– TCI – Tag Control Information:\n– PCP – Priority Code Point: Benutzer-Prioritätsinformationen.\n– DEI – Drop Eligible Indicator: Kann separat oder in Verbindung mit PCP verwendet werden, um anzuzeigen, dass Frames in der Gegenwart von Staus fallen gelassen werden können.\n– VID – VLAN-Identifier: Identifizierung des VLANs, zu dem der Frame gehört.\nErmitteln Sie die maximale Anzahl an VLANs, die in einem Netzwerk eingerichtet werden können. Der Rechenweg ist anzugeben. (3 Punkte)",
                options: ["4.096 VLANs", "4.094 VLANs", "12 VLANs", "8.192 VLANs", "65.536 VLANs"],
                explanation: "Lösung laut Lösungshinweis: 12 Bit für die VLAN-ID, also 2^12 = 4.096 VLANs. (In der Praxis sind die IDs 0 und 4095 reserviert, die Aufgabe fragt aber nach der rechnerischen Zahl.) Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe ab."),
        .choice(id: "ihk-ap2-2019w-ga1-1ac", topic: .netze,
                prompt: "\(w1920Lage)\n\n\(w1920Plan)\n\n1. Handlungsschritt (25 Punkte)\nac) Auf den Verbindungen zwischen den Switchen (z. B. Core-Switch ↔ WS-03) wird VLAN-Tagging eingerichtet.\nErläutern Sie, warum VLAN-Tagging auf diesen Verbindungen zwingend notwendig ist. (4 Punkte)",
                options: ["Der nächste Switch erkennt am Tag, welchem VLAN er die ankommenden Frames zuordnen muss",
                          "Das Tag verschlüsselt die Frames, sodass sie auf der Verbindung nicht mitgelesen werden können",
                          "Das Tag erhöht die Übertragungsrate der Verbindung zwischen den Switchen",
                          "Ohne Tag können die Switche keine MAC-Adressen lernen",
                          "Das Tag ersetzt die IP-Adresse des Default-Gateways in den Frames"],
                explanation: "Lösung laut Lösungshinweis: VLAN-Tags sind notwendig, damit der nächste Switch erkennt, welchem VLAN er die ankommenden Frames zuordnen muss (auf einem Trunk laufen die Frames mehrerer VLANs über dieselbe Verbindung). Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe ac."),
        .match(id: "ihk-ap2-2019w-ga1-1b", topic: .netze,
               prompt: "\(w1920Lage)\n\n1. Handlungsschritt (25 Punkte)\nb) Im Netzwerk der Event GmbH sollen für jede(n) Abteilung/Zweck ein eigenes VLAN eingerichtet werden. Die Anzahl der maximal möglichen IP-Adressen soll dabei auf ein Minimum anhand der Subnetzmaske beschränkt werden. Die Administratoren haben bereits die Hostzahlen ermittelt.\nErgänzen Sie die entsprechende Subnetzmaske (Dezimal-Punkt-Schreibweise) und die IP-Adresse des Default-Gateways. Die IP-Adresse des Default-Gateways soll immer die letzte IP sein. (6 Punkte)\nVLAN Verwaltung: Netz-ID 192.168.10.0, 54 Hosts\nVLAN Entwicklung: Netz-ID 192.168.20.0, 28 Hosts\nVLAN Management: Netz-ID 192.168.40.0, 5 Hosts",
               pairs: [("Verwaltung: Subnetzmaske", "255.255.255.192"), ("Verwaltung: Default-Gateway", "192.168.10.62"),
                       ("Entwicklung: Subnetzmaske", "255.255.255.224"), ("Entwicklung: Default-Gateway", "192.168.20.30"),
                       ("Management: Subnetzmaske", "255.255.255.248"), ("Management: Default-Gateway", "192.168.40.6")],
               extra: ["255.255.255.128", "192.168.10.63"],
               explanation: "Lösung laut Lösungshinweis: 54 Hosts brauchen ein /26 (62 nutzbare Adressen): 255.255.255.192, letzte nutzbare Adresse 192.168.10.62. 28 Hosts: /27 (30 nutzbar): 255.255.255.224, Gateway 192.168.20.30. 5 Hosts: /29 (6 nutzbar): 255.255.255.248, Gateway 192.168.40.6. Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe b."),
        .choice(id: "ihk-ap2-2019w-ga1-1ca", topic: .netze,
                prompt: "\(w1920Lage)\n\n\(w1920Plan)\n\n1. Handlungsschritt (25 Punkte)\nc) Nach der Einrichtung der VLANs überprüfen Sie die Kommunikation im Netzwerk.\nca) Clients in den VLANs haben keinen Zugriff auf den Webserver in der DMZ oder Webserver im Internet.\nSie lassen sich die Routingtabelle auf dem Layer 3-Core-Switch anzeigen:\n172.16.31.0/30 is directly connected, FastEthernet0/8\n192.168.10.0/26 is directly connected, Vlan10\n192.168.20.0/27 is directly connected, Vlan20\n192.168.40.0/29 is directly connected, Vlan199\nErläutern Sie, welcher Fehler in der Routingtabelle vorliegt und wie Sie diesen Fehler beheben. (4 Punkte)",
                options: ["Die Default-Route ins Internet fehlt; Eintrag 0.0.0.0 0.0.0.0 172.16.31.1 bzw. über FastEthernet0/8 ergänzen",
                          "Das Netz 192.168.10.0/26 ist falsch maskiert; auf /24 ändern",
                          "Die Route zum Netz 172.16.31.0/30 fehlt; statische Route auf den Webserver eintragen",
                          "Vlan199 muss durch Vlan40 ersetzt werden; dann funktioniert der Internetzugriff",
                          "Der Core-Switch braucht eine zweite IP-Adresse im Netz 80.90.100.0/30"],
                explanation: "Lösung laut Lösungshinweis: Die Default-Route ins Internet fehlt. Eintrag von 0.0.0.0 0.0.0.0 172.16.31.1 oder 0.0.0.0 0.0.0.0 FastEthernet0/8. Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe ca."),
        .choice(id: "ihk-ap2-2019w-ga1-1cb", topic: .netze,
                prompt: "\(w1920Lage)\n\n\(w1920Plan)\n\n1. Handlungsschritt (25 Punkte)\ncb) Auch nach der Behebung des Fehlers funktioniert die Kommunikation mit dem Internet aus dem Management-VLAN noch nicht. Aus den anderen VLANs ist ein Internetzugriff möglich. Sie überprüfen daraufhin die Routing-Tabelle des Routers:\n80.90.100.0/30, is directly connected, FastEthernet0/1\n172.16.31.0/30 is directly connected, FastEthernet0/0\n192.168.0.0/19 [1/0] via 172.16.31.2\n192.168.250.0/29 is directly connected, FastEthernet1/0\n0.0.0.0/0 [1/0] via 80.90.100.1\nErläutern Sie, welcher Fehler in diesem Fall vorliegt. (4 Punkte)",
                options: ["Die Superroute 192.168.0.0/19 deckt nur 192.168.0.0 bis 192.168.31.255 ab; das Netz 192.168.40.0 (Management) liegt nicht darin",
                          "Die Default-Route 0.0.0.0/0 zeigt auf die falsche Schnittstelle des Providers",
                          "Das Netz 192.168.250.0/29 überschneidet sich mit dem Management-VLAN",
                          "Die Route zum Netz 80.90.100.0/30 muss über FastEthernet0/0 laufen",
                          "Die Metrik [1/0] der Superroute ist zu niedrig, sie überschreibt die Default-Route"],
                explanation: "Lösung laut Lösungshinweis: 192.168.0.0/19 deckt als Superroute nur den IP-Bereich von 192.168.0.0 bis 192.168.31.255 ab. Darin ist aber das Netz 192.168.40.0 für das VLAN 40 (Management) nicht enthalten. Quelle: \(w1920Q), 1. Handlungsschritt, Aufgabe cb."),

        // 2. Handlungsschritt: Netzwerk-Monitoring
        .choice(id: "ihk-ap2-2019w-ga1-2b", topic: .netze,
                prompt: "\(w1920Lage)\n\n2. Handlungsschritt (25 Punkte): Das Netzwerk-Monitoring einrichten\nSie arbeiten an dem Projekt „Netzwerk-Monitoring“ mit und sollen in diesem Zusammenhang folgende Aufgaben bearbeiten.\nb) Zur Analyse und Optimierung der Netzwerkverbindung zu dem Server www.future-gmbh.de soll der MTU-Wert (Maximum Transmission Unit) für diese Verbindung ermittelt werden.\nErläutern Sie eine mögliche Vorgehensweise, um den MTU-Wert einer Netzwerkverbindung mithilfe des Ping-Befehls zu ermitteln. Geben Sie dabei auch ein Beispiel für einen entsprechenden Ping-Befehl einschließlich der erforderlichen Parameter an.\nSyntax: ping [-t] [-a] [-n Anzahl] [-l Größe] [-f] [-i TTL Gültigkeitsdauer] [-v Diensttyp] [-r Anzahl] [-s Anzahl] [[-j Hostliste] | [-k Hostliste]] [-w Zeitlimit] Zielname\nOptionen: -t pingt den Host bis zur Beendigung; -a löst Adressen zu Hostnamen auf; -n Anzahl der zu sendenden Echoanforderungen; -l Größe des Sendepuffers; -f legt das Kennzeichen für „Nicht fragmentieren“ im Paket fest; -i Lebensdauer des Datenpaketes; -v Diensttyp (Type of Service); -r Datensatzroute für Anzahl von Hops (nur IPv4); -s Zeitstempel für Anzahl von Hops (nur IPv4); -j „Loose Source Route“ gemäß Hostliste (nur IPv4); -k „Strict Source Route“ gemäß Hostliste (nur IPv4); -w Zeitlimit in Millisekunden für eine Rückmeldung. (5 Punkte)",
                options: ["Mit -f Fragmentierung verhindern und die Größe (-l) so lange erhöhen oder verringern, bis die Meldung „Paket müsste fragmentiert werden“ gerade ausbleibt; z. B. ping -f -l 1470 www.future-gmbh.de",
                          "Mit -t dauerhaft pingen und aus der durchschnittlichen Antwortzeit den MTU-Wert berechnen; z. B. ping -t www.future-gmbh.de",
                          "Mit -i die TTL schrittweise erhöhen, bis der Server antwortet; die letzte TTL ist der MTU-Wert; z. B. ping -i 64 www.future-gmbh.de",
                          "Mit -n die Anzahl der Echoanforderungen erhöhen, bis Pakete verloren gehen; z. B. ping -n 1500 www.future-gmbh.de",
                          "Mit -a den Hostnamen auflösen und die MTU aus der DNS-Antwort ablesen; z. B. ping -a www.future-gmbh.de"],
                explanation: "Lösung laut Lösungshinweis: Durch Setzen des Parameters -f verhindern, dass fragmentiert wird. Nun werden die Werte für den Parameter -l so lange erhöht bzw. vermindert, bis der Ping-Befehl die Meldung zurückgibt, dass das Paket fragmentiert werden müsste bzw. ohne diese Meldung durchläuft. Beispiel: ping -f -l 1470 www.future-gmbh.de. Hinweis: Die MTU ergibt sich aus der größten erfolgreichen Größe plus 28 Byte für IP- und ICMP-Header. Quelle: \(w1920Q), 2. Handlungsschritt, Aufgabe b."),
        .choice(id: "ihk-ap2-2019w-ga1-2c", topic: .netze,
                prompt: "\(w1920Lage)\n\n2. Handlungsschritt (25 Punkte)\nc) Der Betriebszustand bestimmter Netzwerkgeräte soll mithilfe von SNMP (Simple Network Management Protocol) überwacht werden.\nErläutern Sie in diesem Zusammenhang die grundlegende Arbeitsweise von SNMP. (4 Punkte)\nBearbeitungshinweis: Verwenden Sie in Ihrer Erläuterung folgende Begriffe: MIB (Management-Information-Base), GetRequest, Community-String",
                options: ["Jedes SNMP-fähige Gerät speichert Betriebsinformationen in der MIB; der Administrator fragt sie per GetRequest ab und authentifiziert sich mit dem Community-String",
                          "Der Administrator speichert Betriebsinformationen aller Geräte in der MIB seiner Management-Station; die Geräte senden per GetRequest ihr Passwort, den Community-String",
                          "Die MIB ist ein Verschlüsselungsverfahren; mit dem GetRequest wird ein Community-String für den VPN-Tunnel ausgehandelt",
                          "Jedes Gerät führt in seiner MIB eine Liste der erlaubten Ports; der GetRequest öffnet diese Ports; der Community-String nennt die Gruppe der Geräte",
                          "Die MIB ist eine Routingtabelle; ein GetRequest ändert die Routen; der Community-String ist die Netzwerkadresse"],
                explanation: "Lösung laut Lösungshinweis: Jedes SNMP-fähige Gerät (Router, Switch, Drucker, Server usw.) speichert lokal wichtige Informationen über seinen Betriebszustand in der „Management Information Base (MIB)“. Der Administrator kann von seinem Rechner aus mit dem Befehl „Get-Request“ auf die MIB der Geräte zugreifen. Zur Authentifizierung dient der sogenannte „Community-String“. Quelle: \(w1920Q), 2. Handlungsschritt, Aufgabe c."),
        .choice(id: "ihk-ap2-2019w-ga1-2d", topic: .netze,
                prompt: "\(w1920Lage)\n\n\(w1920Einheiten)\n\n2. Handlungsschritt (25 Punkte)\nd) Sie planen das Remote-Netzwerk-Management. Der externe Zugriff auf das Netzwerk erfolgt über ein VPN-Gateway. Das VPN-Gateway hat eine ADSL 50/10 Mbit/s Internetanbindung.\nDas Remote-Netzwerk-Management soll maximal 2 % Übertragungskapazität der Verbindung beanspruchen.\nJede der zehn Komponenten der Kategorie 1 (z. B. Router) überträgt 1.000 Byte je Abfrage. Komponenten der Kategorie 2 übertragen 500 Byte je Abfrage. Die Abfragen erfolgen einmal pro Sekunde.\nBerechnen Sie die Anzahl der Komponenten der Kategorie 2 (z. B. Drucker), die noch überwacht werden können, ohne dass mehr als 2 % der Übertragungskapazität des VPN-Gateway benötigt werden. (5 Punkte)",
                options: ["30 Komponenten", "50 Komponenten", "150 Komponenten", "25 Komponenten", "120 Komponenten"],
                explanation: "Lösung laut Lösungshinweis: Maßgeblich ist der Upstream von 10 Mbit/s: 2 % von 10 Mbit/s = 200.000 bit/s = 25.000 Byte/s. Die Komponenten der Kategorie 1 brauchen 10 · 1.000 Byte/s = 10.000 Byte/s, es bleiben 15.000 Byte/s. 15.000 / 500 = 30. Es können noch 30 Geräte der Kategorie 2 überwacht werden. Quelle: \(w1920Q), 2. Handlungsschritt, Aufgabe d."),
        .choice(id: "ihk-ap2-2019w-ga1-2ea", topic: .systeme,
                prompt: "\(w1920Lage)\n\n2. Handlungsschritt (25 Punkte)\ne) An der Management-Station soll fortlaufend der jeweilige Anteil von UDP- und TCP-Paketen am IP-Traffic der vergangenen Sekunde in Prozent angezeigt werden. Dazu werden die entsprechenden Werte einmal pro Sekunde beim Internet-Gateway abgefragt. Ein entsprechendes Skript liegt als unvollständiger Entwurf im Pseudocode vor.\nZeile 1: STARTSKRIPT\nZeile 2: LESEN Anzahl TCP-Pakete vom Internet-GW und SPEICHERN in AnzStartTCP;\nZeile 3: LESEN Anzahl UDP-Pakete vom Internet-GW und SPEICHERN in AnzStartUDP;\nZeile 4: LESEN Anzahl IP-Pakete vom Internet-GW und SPEICHERN in AnzStartIP;\nZeile 5: WIEDERHOLE\nZeile 6: VERZÖGERN 1 s\nZeile 7: LESEN Anzahl TCP-Pakete vom Internet-GW und SPEICHERN in AnzEndeTCP;\nZeile 8: LESEN Anzahl UDP-Pakete vom Internet-GW und SPEICHERN in AnzEndeUDP;\nZeile 9: LESEN Anzahl Pakete vom Internet-GW insgesamt SPEICHERN in AnzEndeIP;\nZeile 10: BERECHNE AnteilTCP;\nZeile 11: BERECHNE AnteilUDP;\nZeile 12: ANZEIGEN von AnteilTCP und AnteilUDP;\nZeile 13 bis 15: (leer)\nZeile 16: SOLANGE das Programm nicht beendet wird;\nZeile 17: ENDESKRIPT\nea) Erstellen Sie für den Programmschritt in Zeile 10 den entsprechenden Code (in Pseudocode oder in einer Ihnen vertrauten Programmiersprache). (4 Punkte)",
                options: ["AnteilTCP = ((AnzEndeTCP - AnzStartTCP) / (AnzEndeIP - AnzStartIP)) * 100;",
                          "AnteilTCP = (AnzEndeTCP / AnzEndeIP) * 100;",
                          "AnteilTCP = ((AnzEndeTCP - AnzStartTCP) / AnzStartIP) * 100;",
                          "AnteilTCP = ((AnzEndeIP - AnzStartIP) / (AnzEndeTCP - AnzStartTCP)) * 100;",
                          "AnteilTCP = (AnzEndeTCP + AnzStartTCP) / (AnzEndeIP + AnzStartIP);"],
                explanation: "Lösung laut Lösungshinweis: AnteilTCP = ((AnzEndeTCP − AnzStartTCP) / (AnzEndeIP − AnzStartIP)) * 100; Gefragt ist der Anteil in der vergangenen Sekunde, also zählen die Differenzen (neue Pakete) und nicht die Gesamtzähler. Quelle: \(w1920Q), 2. Handlungsschritt, Aufgabe ea."),
        .choice(id: "ihk-ap2-2019w-ga1-2eb", topic: .systeme,
                prompt: "\(w1920Lage)\n\n2. Handlungsschritt (25 Punkte)\n(Skript wie in Aufgabe ea: Zeilen 2 bis 4 lesen die Startwerte AnzStartTCP, AnzStartUDP, AnzStartIP; Zeilen 7 bis 9 lesen die Endwerte AnzEndeTCP, AnzEndeUDP, AnzEndeIP; in der Schleife zwischen WIEDERHOLE und SOLANGE bleiben die Zeilen 13 bis 15 leer.)\neb) Ergänzen Sie die Zeilen 13 bis 15 so, dass die Variablen „AnzStartTCP, AnzStartUDP und AnzStartIP“ die erforderlichen Werte für den nächsten Schleifendurchgang zugewiesen bekommen. (3 Punkte)",
                options: ["KOPIEREN AnzEndeTCP nach AnzStartTCP; KOPIEREN AnzEndeUDP nach AnzStartUDP; KOPIEREN AnzEndeIP nach AnzStartIP;",
                          "KOPIEREN AnzStartTCP nach AnzEndeTCP; KOPIEREN AnzStartUDP nach AnzEndeUDP; KOPIEREN AnzStartIP nach AnzEndeIP;",
                          "KOPIEREN AnteilTCP nach AnzStartTCP; KOPIEREN AnteilUDP nach AnzStartUDP; KOPIEREN AnteilTCP nach AnzStartIP;",
                          "SETZE AnzStartTCP auf 0; SETZE AnzStartUDP auf 0; SETZE AnzStartIP auf 0;",
                          "KOPIEREN AnzEndeIP nach AnzStartTCP; KOPIEREN AnzEndeIP nach AnzStartUDP; KOPIEREN AnzEndeIP nach AnzStartIP;"],
                explanation: "Lösung laut Lösungshinweis: KOPIEREN AnzEndeTCP nach AnzStartTCP; KOPIEREN AnzEndeUDP nach AnzStartUDP; KOPIEREN AnzEndeIP nach AnzStartIP; Die Reihenfolge der Anweisungen ist beliebig. Die Endwerte dieses Durchlaufs sind die Startwerte des nächsten. Quelle: \(w1920Q), 2. Handlungsschritt, Aufgabe eb."),

        // 3. Handlungsschritt: Serverbetrieb
        .choice(id: "ihk-ap2-2019w-ga1-3a", topic: .systeme,
                prompt: "\(w1920Lage)\n\n3. Handlungsschritt (25 Punkte): Den Serverbetrieb sicherstellen\nDie Event GmbH will ihre Serverlandschaft modernisieren und absichern.\na) Die IT-Abteilung der Event GmbH plant den Einsatz von aktuellen Blade-Serversystemen.\nNennen Sie drei Vorteile, die ein solches Blade-Serversystem gegenüber klassischen Serversystemen aufweist. (3 Punkte)",
                options: ["Höhere Verarbeitungsleistung auf geringerer Rack-Standfläche; vereinfachte Verkabelung; reduzierter Stromverbrauch",
                          "Jeder Blade braucht ein eigenes Netzteil und eine eigene Kühlung; höhere Ausfallsicherheit durch getrennte Gehäuse; keine gemeinsame Verkabelung",
                          "Keine Virtualisierung mehr nötig; unbegrenzte Speicherkapazität; keine Wartung",
                          "Geringere Anschaffungskosten je Server in jedem Fall; mehr Platzbedarf im Rack; einfachere Einzelkühlung",
                          "Betrieb ohne Netzwerkanbindung; eingebaute USV in jedem Blade; kostenlose Betriebssystemlizenz"],
                explanation: "Lösung laut Lösungshinweis (u. a.): Server auf einer Steckkarte mit Prozessoren, Speicher, integrierten Netzwerk-Controllern und I/O-Ports; höhere Verarbeitungsleistung auf geringerer Rack-Standfläche; vereinfachte Verkabelung; reduzierter Stromverbrauch. Quelle: \(w1920Q), 3. Handlungsschritt, Aufgabe a."),
        .choice(id: "ihk-ap2-2019w-ga1-3b", topic: .systeme,
                prompt: "\(w1920Lage)\n\n3. Handlungsschritt (25 Punkte)\nb) Sie sollen ein entsprechendes Betriebssystem für die Installation des Datenbank-Servers auswählen. Bei der Recherche dazu stoßen Sie auf Betriebssysteme in der Variante LTS.\nErklären Sie den Begriff „LTS“ und beschreiben Sie, warum der Einsatz einer LTS-Variante für Server sinnvoll ist. (3 Punkte)",
                options: ["LTS = Long Term Support: länger als üblich Aktualisierungen, vor allem Sicherheitskorrekturen, auch wenn schon ein neuerer Versionszweig erscheint; so bleibt der Server lange sicher, ohne dass das System gewechselt werden muss",
                          "LTS = Low Traffic System: Das Betriebssystem erzeugt wenig Netzwerkverkehr und eignet sich deshalb für Server",
                          "LTS = Licensed Terminal Server: Das System enthält bereits alle Lizenzen für Terminalzugriffe",
                          "LTS = Live Test Software: Das System wird laufend mit neuen Funktionen getestet, deshalb ist es für Server besonders aktuell",
                          "LTS = Local Time Synchronisation: Das System gleicht automatisch die Uhrzeit mit allen Clients ab"],
                explanation: "Lösung laut Lösungshinweis: LTS (Long Term Support): eine über das übliche Maß hinausgehende Versorgung des Betriebssystems mit Aktualisierungen, die üblicherweise zur Behebung von sicherheitskritischen Programmfehlern gedacht sind. Aktualisierungen werden auch bei Erscheinen eines neueren Versionszweiges weiterhin entwickelt und angeboten. Quelle: \(w1920Q), 3. Handlungsschritt, Aufgabe b."),
        .choice(id: "ihk-ap2-2019w-ga1-3c", topic: .systeme,
                prompt: "\(w1920Lage)\n\n3. Handlungsschritt (25 Punkte)\nc) Die Stromversorgung der eingesetzten Server soll durch eine USV gesichert werden. Sie stoßen bei Ihren Recherchen auf USVs mit den Betriebsmodi VFD, VI und VFI.\nOrdnen Sie die Bezeichnungen den entsprechenden Blockschaltbildern zu und nennen Sie zwei spezifische Schutzeigenschaften einer VFI-USV. (7 Punkte)\n[Abbildung nicht übernommen: drei Blockschaltbilder aus Netzspannung, Gleichrichter, Wechselrichter, Batterie und Verbraucher; hier wird nur der Teil „zwei spezifische Schutzeigenschaften einer VFI-USV“ abgefragt.]",
                options: ["Erzeugt ständig eine eigene Netzspannung (Dauerwandler); Verbraucher werden dauerhaft versorgt, während die Batterie geladen wird; keine Störspannungen, Frequenzstörungen oder Spannungsverzerrungen",
                          "Schaltet erst bei Netzausfall auf Batterie um (Offline-Betrieb); Verbraucher hängen im Normalbetrieb direkt am Netz; kurze Umschaltzeit",
                          "Regelt nur Unter- und Überspannung über einen Spartransformator; Frequenzstörungen werden durchgereicht",
                          "Speist die Verbraucher im Normalbetrieb direkt aus der Batterie; die Netzspannung dient nur dem Laden",
                          "Schützt ausschließlich vor Blitzschlag über einen Überspannungsableiter, nicht vor Netzausfall"],
                explanation: "Lösung laut Lösungshinweis: VFI (Voltage and Frequency Independent from Mains Supply), Dauerwandler- oder Online-USV: erzeugt ständig eine eigene Netzspannung; angeschlossene Verbraucher werden dauerhaft mit Netzspannung versorgt, zeitgleich werden die Akkus geladen; keine Störspannungen, elektromagnetischen Einflüsse, Frequenzstörungen und Spannungsverzerrungen. Zuordnung (aus dem Lösungshinweis): VFD = Standby- oder Offline-USV, VI = Line-Interactive-USV, VFI = Online-USV. Quelle: \(w1920Q), 3. Handlungsschritt, Aufgabe c."),
        .choice(id: "ihk-ap2-2019w-ga1-3d", topic: .systeme,
                prompt: "\(w1920Lage)\n\n3. Handlungsschritt (25 Punkte)\nd) Die aktuell eingesetzte Unterbrechungsfreie Stromversorgung (Online-USV) ist durch drei Firmen-Server mit jeweils 750 VA belastet.\nAngaben zur Online-USV:\n• Leistungsabgabe: max. 3.000 VA\n• Akkumulatoren: 24 Stück mit je 12 V/3,6 Ah\n• Zustand zum Zeitpunkt des Stromausfalls: zu 100 % geladen, lineare Entladung bis zum Shutdown\nBei einem Netzausfall soll die USV den Betrieb der Server solange aufrechterhalten, bis die Akkus eine Restladung von 35 % erreicht haben. Danach sollen die Server kontrolliert heruntergefahren werden.\nErmitteln Sie die Zeit, in der der Server bis zum Herunterfahren mit Energie versorgt werden kann, in vollen Minuten. (4 Punkte)",
                options: ["17 Minuten", "27 Minuten", "18 Minuten", "46 Minuten", "7 Minuten"],
                explanation: "Lösung laut Lösungshinweis: Last 3 · 750 VA = 2.250 VA. Nutzbare Energie: 24 · 12 V · 3,6 Ah · 0,65 = 673,92 Wh. t = 673,92 Wh / 2.250 VA = 0,29952 h = 17,9712 min, also 17 volle Minuten. Quelle: \(w1920Q), 3. Handlungsschritt, Aufgabe d."),
        .choice(id: "ihk-ap2-2019w-ga1-3eb", topic: .systeme,
                prompt: "\(w1920Lage)\n\n3. Handlungsschritt (25 Punkte)\ne) Sie sollen in der Event GmbH ein logisches Laufwerk mit einem RAID 6-Verbund einrichten. Dazu stehen Ihnen fünf Festplatten mit je 1,2 TiB zur Verfügung.\n(ea: Prinzip der Datenhaltung schematisch darstellen, hier nicht übernommen.)\neb) Berechnen Sie die Nettospeicherkapazität dieses RAID 6-Verbunds. (3 Punkte)",
                options: ["3,6 TiB", "4,8 TiB", "2,4 TiB", "6,0 TiB", "3,0 TiB"],
                explanation: "Lösung laut Lösungshinweis: (5 − 2) Festplatten · 1,2 TiB = 3,6 TiB. RAID 6 verwendet zwei Platten-Äquivalente für die doppelte Parität. Quelle: \(w1920Q), 3. Handlungsschritt, Aufgabe eb."),

        // 4. Handlungsschritt: IT-Sicherheit
        .choice(id: "ihk-ap2-2019w-ga1-4a", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n4. Handlungsschritt (25 Punkte): Die IT-Sicherheit verbessern\nBei der Event GmbH soll der IT-Betrieb auf Sicherheit überprüft werden.\na) Bei der Überprüfung werden alle Maßnahmen der IT-Sicherheit betrachtet. Zusätzliche Maßnahmen sollen eingeführt werden.\nErgänzen Sie die Tabelle um jeweils eine weitere entsprechende Maßnahme. (6 Punkte)\nVorgegeben: Aspekt „Logisch (Software)“: Netzwerk-Firewall; „Organisatorisch (Geschäftsprozesse)“: Benutzerschulung (Durchführung einer Datenschutzunterweisung); „Physikalisch (Bauliche Maßnahme)“: Backup-Server in anderem Brandabschnitt.\nGesucht ist je Aspekt eine weitere Maßnahme mit Erläuterung.",
                options: ["Logisch: Virenscanner; organisatorisch: Geschäftsprozess für Datensicherung; physikalisch: Zutrittskontrolle mit Chipkarte",
                          "Logisch: Zutrittskontrolle mit Chipkarte; organisatorisch: Virenscanner; physikalisch: Geschäftsprozess für Datensicherung",
                          "Logisch: Benutzerschulung; organisatorisch: Netzwerk-Firewall; physikalisch: Virenscanner",
                          "Logisch: Geschäftsprozess für Datensicherung; organisatorisch: Zutrittskontrolle mit Chipkarte; physikalisch: Virenscanner",
                          "Logisch: Backup-Server in anderem Brandabschnitt; organisatorisch: Virenscanner; physikalisch: Benutzerschulung"],
                explanation: "Lösung laut Lösungshinweis (weitere sinnvolle Lösungen sind möglich): Logisch: Virenscanner (Schadsoftware kann auf dem Rechner nicht ausgeführt werden). Organisatorisch: Geschäftsprozess für Datensicherung (es ist geklärt, wer die Datensicherung durchführt und wie zu verfahren ist). Physikalisch: Einführung einer Zutrittskontrolle mittels Chipkarte (nur berechtigte Personen können Gebäude bzw. Räume betreten). Quelle: \(w1920Q), 4. Handlungsschritt, Aufgabe a."),
        .choice(id: "ihk-ap2-2019w-ga1-4b", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n\(w1920Plan)\n\n4. Handlungsschritt (25 Punkte)\nb) Zur Absicherung des Datenverkehrs zum Internet wird eine DMZ eingesetzt.\nBeschreiben Sie, warum es sinnvoll ist, die Homepage auf einem Webserver in der DMZ zu hosten. (3 Punkte)",
                options: ["Eine Firewall trennt die DMZ vom internen Netz; wird der Webserver kompromittiert, hat der Angreifer keinen direkten Zugriff auf das interne Netz",
                          "Der Webserver in der DMZ ist für Angreifer aus dem Internet unsichtbar, weil die DMZ keine IP-Adressen verwendet",
                          "In der DMZ werden alle Daten des Webservers automatisch verschlüsselt und gesichert",
                          "Der Webserver erhält in der DMZ zusätzliche Bandbreite, weil der interne Verkehr bevorzugt wird",
                          "Die DMZ verhindert grundsätzlich jeden Zugriff aus dem Internet auf den Webserver"],
                explanation: "Lösung laut Lösungshinweis: Das interne Netz ist durch eine Firewall zur DMZ abgetrennt. Bei einer Kompromittierung des Webservers ist durch diese Firewall eine Abgrenzung zum internen Netz gegeben. Der Angreifer hat keinen direkten Zugriff auf das interne Netz. Quelle: \(w1920Q), 4. Handlungsschritt, Aufgabe b."),
        .choice(id: "ihk-ap2-2019w-ga1-4c", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n4. Handlungsschritt (25 Punkte)\nc) Die Event GmbH betreibt zum Aufspüren von Angriffen einen Honeypot.\nErklären Sie kurz die Funktionsweise eines Honeypot. (3 Punkte)",
                options: ["Ein präpariertes System spielt dem Angreifer ein verwundbares System vor; alle Aktivitäten werden aufgezeichnet, um Vorgehen und Schwachstellen zu analysieren",
                          "Ein Honeypot verschlüsselt alle Daten des Netzes und gibt sie nur gegen ein Passwort frei",
                          "Ein Honeypot blockiert Angriffe auf Schicht 3 und 4 und ersetzt die Firewall",
                          "Ein Honeypot ist ein Backup-Server, der bei einem Angriff die Daten des Produktivsystems übernimmt",
                          "Ein Honeypot prüft Passwörter der Benutzer auf Komplexität und sperrt schwache Konten"],
                explanation: "Lösung laut Lösungshinweis: Ein Honeypot ist ein besonders präpariertes System, das einem Angreifer ein verwundbares System vorspielt. Alle Aktivitäten eines Angreifers werden aufgezeichnet. Aus den Aufzeichnungen kann die Vorgehensweise rekonstruiert werden, um Schwachstellen zu analysieren, Gegenmaßnahmen zu entwickeln oder Beweise für strafrechtliche Schritte zu sammeln. Quelle: \(w1920Q), 4. Handlungsschritt, Aufgabe c."),
        .choice(id: "ihk-ap2-2019w-ga1-4d", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n4. Handlungsschritt (25 Punkte)\nd) Das Netzwerk soll durch entsprechende Firewall-Regeln abgesichert werden.\nDie Event GmbH schützt ihr Netz mithilfe einer DMZ, bei der eine Stateful Packet Inspection (SPI) als äußere Firewall zum Einsatz kommt. Dazu wurde die Regel 1 aufgestellt.\nErgänzen Sie die übrigen Regeln, um den VLANs Verwaltung und Entwicklung die Protokolle HTTPS, DNS, SMTP und POP3 zu erlauben. Dem Management-VLAN wird unbeschränkter Zugriff auf das Internet gegeben. Der übrige Datenverkehr wird verboten. (8 Punkte)\nHinweis: Die Anzahl der Lösungszeilen lässt keinen Rückschluss auf die benötigten Regeln zu.\nTabelle mit den Spalten Nr, Aktion, Protokoll, Quell-IP, Ziel-IP, Q-Port, Z-Port, Von Interface, Nach Interface. Regel 1: Permit, TCP, VLAN-Verw und VLAN-Entw, Any, >1024, 80, LAN, WAN.",
                options: ["2: Permit TCP, Verw/Entw → Any, >1024 → 443; 3: Permit UDP, >1024 → 53; 4: Permit TCP → 25; 5: Permit TCP → 110; 6: Permit IP, VLAN-Management → Any; 7: Deny IP, Any → Any (alle LAN → WAN)",
                          "2: Permit TCP → 443; 3: Permit TCP → 53; 4: Permit TCP → 110; 5: Permit TCP → 25; 6: Deny IP, Any → Any; 7: Permit IP, VLAN-Management → Any",
                          "2: Permit TCP → 443; 3: Permit UDP → 53; 4: Permit TCP → 25; 5: Permit TCP → 143; 6: Permit IP, VLAN-Management → Any; 7: Deny IP, Any → Any",
                          "2: Permit TCP → 80; 3: Permit UDP → 53; 4: Permit TCP → 25; 5: Permit TCP → 110; 6: Permit IP, VLAN-Management → Any (kein Deny)",
                          "2: Permit TCP → 443; 3: Permit UDP → 53; 4: Permit TCP → 25; 5: Permit TCP → 110; 6: Deny IP, VLAN-Management → Any; 7: Deny IP, Any → Any"],
                explanation: "Lösung laut Lösungshinweis: Regel 2 Permit TCP, VLAN-Verw/VLAN-Entw → Any, Quellport >1024, Zielport 443 (LAN → WAN); Regel 3 Permit UDP → 53 (DNS); Regel 4 Permit TCP → 25 (SMTP); Regel 5 Permit TCP → 110 (POP3); Regel 6 Permit IP, VLAN-Management → Any; Regel 7 Deny IP, Any → Any. Wichtig: Die Deny-Regel steht zuletzt, weil Firewall-Regeln von oben nach unten ausgewertet werden. Quelle: \(w1920Q), 4. Handlungsschritt, Aufgabe d."),
        .choice(id: "ihk-ap2-2019w-ga1-4e", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n4. Handlungsschritt (25 Punkte)\ne) Der Webauftritt der Event GmbH wird dynamisch aus Datenbankinhalten und Formularen erzeugt. Der Webserver der Event GmbH ist durch eine SPI-Firewall geschützt. Trotz dieses Schutzes ist es Angreifern gelungen, Daten bzw. Schadcode einzuspielen.\nBeschreiben Sie eine mögliche Angriffsmethode und warum die SPI-Firewall gegen diese keinen Schutz bietet. (5 Punkte)",
                options: ["SQL-Injection: über Eingabefelder werden SQL-Befehle übergeben, um Benutzernamen, Passwörter und andere Daten auszulesen; die Firewall arbeitet auf Schicht 3 und 4 und bemerkt den Inhalt nicht",
                          "Ping-Flood: der Webserver wird mit ICMP-Paketen überlastet; die Firewall lässt ICMP grundsätzlich unbeschränkt durch",
                          "Portscan: Angreifer lesen alle offenen Ports aus; die SPI-Firewall kennt keine Ports",
                          "ARP-Spoofing: Angreifer fälschen MAC-Adressen im Webserver-Netz; die Firewall arbeitet nur auf Schicht 7",
                          "Brute-Force auf das WLAN-Passwort; die Firewall prüft keine WLAN-Verbindungen"],
                explanation: "Lösung laut Lösungshinweis: Code Injection oder SQL-Injection. Bei dynamisch erzeugten Webseiten werden Rückgabewerte aus Formularen durch Skriptsprache oder Programmcode verarbeitet; wird Schadcode durch präparierte Formularwerte gesendet, bemerkt die Firewall nichts, da sie auf Schicht 3 und 4 arbeitet und der Inhalt auf höherer Schicht als gültig betrachtet wird. Andere Lösungen sind möglich. Quelle: \(w1920Q), 4. Handlungsschritt, Aufgabe e."),

        // 5. Handlungsschritt: Benutzeranlage
        .choice(id: "ihk-ap2-2019w-ga1-5aa", topic: .systeme,
                prompt: "\(w1920Lage)\n\n5. Handlungsschritt (25 Punkte): Die Benutzeranlage erläutern\nDie Event GmbH verwaltet alle ihre Benutzer in einer zentralen Datenbank.\na) Neue Benutzer werden per Skript aus einer csv-Datei in diese Datenbank importiert. Die csv-Datei „NeueBenutzer.csv“ hat folgenden Aufbau:\nVorname; Name; Abteilung\nAlfred; Huber; Verwaltung\nMaria; Maier; Verwaltung\nWerner; Schmidt; Entwicklung\nWilhelm; Thor; Administration\nDas Anlegen der Benutzer erfolgt mit folgendem Skript:\n#Schritt 1:\n$ImportDatei = \"NeueBenutzer.csv\"\n$Vorname = \"\"\n$Nachname = \"\"\n$Abteilung = \"\"\n$HomeDirectory = \"\"\n#Schritt 2:\n$Users = Import-CSV -Delimiter ';' $ImportDatei\n#Schritt 3:\nforeach ($User in $Users) {\n$Vorname = $User.\"Vorname\"\n$Nachname = $User.\"Nachname\"\n$Abteilung = $User.\"Abteilung\"\n$HomeDirectory = \"\\\\server\\user\\$Abteilung\\$Nachname\"\n#Schritt 4:\nNew-User -Name $Nachname -GivenName $Vorname -HomeDirectory $HomeDirectory -HomeDrive \"H:\"\n#Schritt 5:\nmkdir $HomeDirectory }\nKommentieren Sie für die Dokumentation des Codes die einzelnen Schritte: (10 Punkte)",
                options: ["1: Variablen initialisieren; 2: Importdatei spaltenweise am Trenner „;“ in $Users einlesen; 3: $Users zeilenweise durchlaufen und Vorname, Nachname, Abteilung, Home-Verzeichnis füllen; 4: Benutzer mit diesen Eigenschaften anlegen, Home-Laufwerk H: setzen; 5: Home-Verzeichnis anlegen",
                          "1: Datenbank öffnen; 2: Benutzer löschen; 3: csv-Datei sortieren; 4: Passwörter vergeben; 5: Backup erstellen",
                          "1: Importdatei anlegen; 2: Benutzer aus der Datenbank lesen; 3: Alle Benutzer in die csv-Datei schreiben; 4: Home-Laufwerk löschen; 5: Verzeichnis umbenennen",
                          "1: Variablen löschen; 2: csv-Datei nach Abteilungen filtern; 3: Nur die Abteilung Verwaltung anlegen; 4: Home-Laufwerk auf C: setzen; 5: Verzeichnis freigeben",
                          "1: Skript beenden; 2: Trenner „,“ festlegen; 3: Schleife abbrechen; 4: Benutzer sperren; 5: Home-Verzeichnis löschen"],
                explanation: "Lösung laut Lösungshinweis: Schritt 1 Initialisierung der Variablen (1 Punkt); Schritt 2 spaltenweises Einlesen der Importdatei anhand des Trenners „;“ in die Variable $Users (2 Punkte); Schritt 3 zeilenweises Lesen von $Users und Füllen der Variablen $Vorname, $Nachname, $Abteilung und $HomeDirectory (3 Punkte); Schritt 4 Anlegen des Benutzers mit Vorname, Name und Home-Verzeichnis, Setzen des Home-Laufwerks auf H: (3 Punkte); Schritt 5 Anlegen des Home-Verzeichnisses (1 Punkt). Hinweis: Im Skript heißt die Spalte „Nachname“, in der csv-Datei „Name“; so steht es im Original. Quelle: \(w1920Q), 5. Handlungsschritt, Aufgabe aa."),
        .choice(id: "ihk-ap2-2019w-ga1-5ab", topic: .sicherheit,
                prompt: "\(w1920Lage)\n\n5. Handlungsschritt (25 Punkte)\nab) Das Benutzerpasswort wird in der Datenbank nicht im Klartext, sondern als Hashwert abgespeichert.\nErläutern Sie, warum es sinnvoll ist, das Passwort als Hashwert zu speichern. (3 Punkte)",
                options: ["Aus dem Hashwert kann nicht auf das Passwort geschlossen werden; bei der Prüfung kann der Passwort-Hashwert übertragen und mit dem gespeicherten Hashwert verglichen werden",
                          "Der Hashwert lässt sich jederzeit wieder in das Klartextpasswort entschlüsseln, falls der Benutzer es vergisst",
                          "Der Hashwert ist kürzer als das Passwort und spart deshalb Speicherplatz in der Datenbank",
                          "Der Hashwert verhindert, dass Benutzer schwache Passwörter wählen",
                          "Der Hashwert ersetzt den Benutzernamen und macht ihn damit anonym"],
                explanation: "Lösung laut Lösungshinweis: Aus dem Hashwert kann nicht auf das Passwort geschlossen werden. Bei der Prüfung von Benutzername und Passwort kann der Passwort-Hashwert über das Netz übermittelt und mit dem gespeicherten Hashwert verglichen werden. Quelle: \(w1920Q), 5. Handlungsschritt, Aufgabe ab."),
        .multiple(id: "ihk-ap2-2019w-ga1-5ac", topic: .sicherheit,
                  prompt: "\(w1920Lage)\n\n5. Handlungsschritt (25 Punkte)\nac) Die Unternehmensleitung beschließt, die Passwortsicherheit zu erhöhen.\nErläutern Sie zwei Maßnahmen, mit denen die Passwortsicherheit erhöht werden kann. (4 Punkte)\n(Hier: Wählen Sie die Maßnahmen, die die Passwortsicherheit erhöhen.)",
                  correct: ["Erzwingen einer Passwortchronik", "Ablaufzeit für Passwörter", "Passwörter müssen Komplexitätsbedingungen erfüllen"],
                  wrong: ["Passwörter im Klartext in der Datenbank speichern", "Ein gemeinsames Passwort für alle Mitarbeiter einer Abteilung", "Passwörter nie ändern lassen, damit sie nicht vergessen werden"],
                  explanation: "Lösung laut Lösungshinweis (u. a.): Erzwingen einer Passwortchronik, Ablaufzeit für Passwörter, Passwort muss den Komplexitätsbedingungen entsprechen. Gefordert waren zwei Maßnahmen. Quelle: \(w1920Q), 5. Handlungsschritt, Aufgabe ac."),
        .match(id: "ihk-ap2-2019w-ga1-5ba", topic: .sicherheit,
               prompt: "\(w1920Lage)\n\n5. Handlungsschritt (25 Punkte)\nb) Die Administratoren der Event GmbH möchten ihrem Provider, der iKomP AG, Remotezugriff auf den Router zu Wartungszwecken ermöglichen.\nba) Dazu wurde auf einem Notebook der iKomP AG ein VPN-Client mit folgender Konfiguration eingerichtet.\ndev tun\ncipher AES-256\nauth SHA\nremote 80.90.100.2\nErläutern Sie die Bedeutung der Begriffe (Beispiel: dev tun = VPN-Modus: Tunnelmodus): (6 Punkte)",
               pairs: [("cipher AES-256", "Verschlüsselung mit AES"), ("auth SHA", "Authentifizierung und Integrität mit SHA"), ("remote 80.90.100.2", "IP des VPN-Partners")],
               extra: ["Pfad der Schlüsseldatei", "Adresse des DNS-Servers"],
               explanation: "Lösung laut Lösungshinweis: cipher AES-256 = Verschlüsselung mit AES; auth SHA = Authentifizierung und Integrität mit SHA; remote 80.90.100.2 = IP des VPN-Partners. Quelle: \(w1920Q), 5. Handlungsschritt, Aufgabe ba."),
        .choice(id: "ihk-ap2-2019w-ga1-5bb", topic: .netze,
                prompt: "\(w1920Lage)\n\n5. Handlungsschritt (25 Punkte)\nbb) Für die IPsec-VPN-Verbindung wird die MTU auf 1.400 Byte heruntergesetzt.\nErläutern Sie, warum diese Maßnahme sinnvoll ist. (2 Punkte)",
                options: ["Bei kleinerer MTU bleibt im Paket Platz für zusätzliche Informationen (z. B. Authentifizierung, Integrität), ohne dass Pakete fragmentiert werden müssen",
                          "Eine kleinere MTU erhöht die Verschlüsselungsstärke des Tunnels",
                          "Eine kleinere MTU erhöht die Übertragungsrate, weil die Pakete schneller ankommen",
                          "Bei kleinerer MTU wird der Hashwert der Pakete nicht mehr berechnet",
                          "Eine MTU von 1.400 Byte ist für IPsec vorgeschrieben, sonst verweigert der Router den Tunnel"],
                explanation: "Lösung laut Lösungshinweis: Die Maßnahme ist sinnvoll, da bei einer kleineren MTU weitere Informationen (z. B. Authentifizierung, Integrität) im Paket untergebracht werden können, ohne dass Pakete fragmentiert werden müssen. Quelle: \(w1920Q), 5. Handlungsschritt, Aufgabe bb."),
    ]

    // MARK: - Winter 2019/20, WiSo

    private static let w1920WiSoLage = "Situation: Sie sind Mitarbeiter/-in der DataSec IT GmbH. Die DataSec IT GmbH ist ein Dienstleistungsunternehmen im Bereich der IT-Sicherheit. Die folgenden Aufgaben beziehen sich auf dieses Unternehmen."

    private static func w1920WiSoChoice(_ nr: String, _ topic: ExamTopic, _ text: String, _ options: [String], _ explanation: String) -> ExamCard {
        .choice(id: "ihk-ap2-2019w-wiso-\(nr)", topic: topic,
                prompt: "\(w1920WiSoLage)\n\n\(nr). Aufgabe\n\(text)",
                options: options,
                explanation: "\(explanation) Lösung laut Lösungshinweis (Vorläufige Lösungen). Quelle: IHK AP2 FiSi Winter 2019/20, WiSo, Aufgabe \(nr).")
    }

    static let ihkW1920WiSo: [ExamCard] = [
        w1920WiSoChoice("1", .unternehmen, "Zur DataSec IT GmbH liegen folgende Daten vor:\nIT-Dienstleister\n45 % Marktanteil in der Region\n244 Beschäftigte\n1.610.000 EUR Gewinn im Jahr 2018\nWelche der folgenden Angaben trifft auf die DataSec IT GmbH zu?",
                        ["Unternehmen des tertiären Sektors", "Genossenschaftlicher Betrieb", "Monopolist", "Gemeinwirtschaftliches Unternehmen", "Versorgungsunternehmen"],
                        "Ein IT-Dienstleister erbringt Dienstleistungen und gehört damit zum tertiären Sektor; 45 % Marktanteil sind kein Monopol."),
        w1920WiSoChoice("2", .arbeitsrecht, "Die DataSec IT GmbH möchte ihre Belegschaft durch Einstellungen vergrößern. Bei der Einstellung von Personal ist das „Allgemeine Gleichbehandlungsgesetz (AGG)“ zu berücksichtigen.\n§ 1 Ziel des Gesetzes: Ziel des Gesetzes ist es, Benachteiligungen aus Gründen der Rasse oder der ethnischen Herkunft, des Geschlechts, der Religion oder Weltanschauung, einer Behinderung, des Alters oder der sexuellen Identität zu verhindern oder zu beseitigen.\nWelcher der folgenden Sachverhalte entspricht dem „Allgemeinen Gleichbehandlungsgesetz“?",
                        ["Bei der Auswahl des Personals werden ausschließlich die Qualifikationen der Bewerberinnen und Bewerber als Auswahlkriterium zugrunde gelegt.",
                         "Vor der Sichtung der Bewerbungsunterlagen werden Name und Alter der Bewerberinnen und Bewerber offengelegt.",
                         "In der Stellenanzeige wird darauf hingewiesen, dass Bewerber aus Italien bevorzugt werden.",
                         "Bei der Auswahl des Personals werden Frauen bevorzugt.",
                         "In den Stellenanzeigen ist folgender Hinweis aufgenommen: „Wir sind ein junges, dynamisches Team, deshalb werden nur Bewerberinnen berücksichtigt, die unter 35 Jahre alt sind.“"],
                        "Nur die Auswahl nach Qualifikation benachteiligt niemanden; die anderen Fälle knüpfen an Herkunft, Geschlecht oder Alter an."),
        w1920WiSoChoice("3", .arbeitsrecht, "Die DataSec IT GmbH hat mit der Informatikkauffrau Luise Schnell einen Einzelarbeitsvertrag geschlossen. Im Arbeitsvertrag wurde keine Regelung über den Urlaubsanspruch von Frau Schnell getroffen. Die DataSec IT GmbH ist nicht tarifgebunden.\nWelche der folgenden Aussagen über den Urlaubsanspruch von Frau Schnell trifft zu?",
                        ["Da der Arbeitsvertrag keine Urlaubsregelung enthält, steht ihr der Mindesturlaub nach Bundesurlaubsgesetz zu.",
                         "Der Arbeitsvertrag ist nichtig.",
                         "Der Mindesturlaubsanspruch gemäß Bundesurlaubsgesetz beträgt 30 Werktage.",
                         "Der Urlaubsanspruch muss zwischen Frau Schnell und der DataSec IT GmbH jedes Jahr neu verhandelt werden.",
                         "Es gilt der durchschnittliche Urlaubsanspruch der Tarifverträge der Branche."],
                        "Der gesetzliche Mindesturlaub gilt auch ohne Vereinbarung (24 Werktage bei sechs Arbeitstagen pro Woche, nicht 30)."),
        .multiple(id: "ihk-ap2-2019w-wiso-4", topic: .arbeitsrecht,
                  prompt: "\(w1920WiSoLage)\n\n4. Aufgabe\nBei der Überprüfung von Personalunterlagen stellt die Personalleiterin fest, dass bei zwei Personen der nachstehend aufgeführten Mitarbeiter ein besonderer Kündigungsschutz besteht, weil sie zu einer bestimmten Arbeitnehmergruppe gehören.\nFür welche der folgenden Personen besteht ein besonderer Kündigungsschutz? (Zwei Personen)",
                  correct: ["Christina Maxin, 21 Jahre, Auszubildende im 2. Ausbildungsjahr.", "Martin Böhling, 28 Jahre, fünfjährige Betriebszugehörigkeit, ist schwerbehindert."],
                  wrong: ["Patrick Grün, seit zehn Jahren Geschäftsführer der DataSec IT GmbH.", "Peter Schröder, 58 Jahre, Witwer, drei Jahre Betriebszugehörigkeit.", "Sarah Stüven, 41 Jahre, 3-fache Mutter, alleinerziehend.", "Harald Beckedorf, ehemaliges Betriebsratsmitglied, vor drei Jahren aus dem Amt als Betriebsrat ausgeschieden."],
                  explanation: "Besonderen Kündigungsschutz haben unter anderem Auszubildende (nach der Probezeit) und schwerbehinderte Menschen. Lösung laut Lösungshinweis (Vorläufige Lösungen). Quelle: IHK AP2 FiSi Winter 2019/20, WiSo, Aufgabe 4."),
        w1920WiSoChoice("5", .arbeitsrecht, "Heinz Meyer, ein Mitarbeiter der DataSec IT GmbH, hat gekündigt.\nWelche der folgenden Unterlagen muss Heinz Meyer – ggf. auf Verlangen – ausgehändigt werden?",
                        ["Qualifiziertes Arbeitszeugnis", "Lebenslauf", "Arbeitsvertrag", "Zeugniskopien", "Leistungsbeurteilungen aus Mitarbeitergesprächen"],
                        "Anspruch besteht auf ein (auf Verlangen qualifiziertes) Arbeitszeugnis."),
        w1920WiSoChoice("6", .arbeitsrecht, "Der Auszubildenden Sandra Kopper wird in der DataSec IT GmbH nach Abschluss der Ausbildung eine Stelle angeboten. Der Arbeitsvertrag ist auf ein Jahr befristet.\nWelche der folgenden Konsequenzen ergibt sich für den Arbeitsvertrag aus der Befristung?\nDie DataSec IT GmbH ...",
                        ["darf den Arbeitsvertrag nach dem Jahr für ein weiteres Jahr befristet verlängern.",
                         "muss den Arbeitsvertrag zum Ablauf der Vertragszeit kündigen, da sonst ein unbefristeter Arbeitsvertrag entsteht.",
                         "darf den Arbeitsvertrag nicht verlängern.",
                         "darf den Arbeitsvertrag vor Ablauf des Jahres nicht kündigen.",
                         "ist an keine tariflichen Vereinbarungen gebunden."],
                        "Eine sachgrundlose Befristung darf bis zur Gesamtdauer von zwei Jahren höchstens dreimal verlängert werden."),
        w1920WiSoChoice("7", .arbeitsrecht, "Die DataSec IT GmbH und die Arbeitnehmer sind mit Arbeitsverträgen Pflichten eingegangen.\nIn welchem der folgenden Fälle wird in der DataSec IT GmbH gegen die Pflichten aus dem Arbeitsvertrag verstoßen?",
                        ["Ein Mitarbeiter der DataSec IT GmbH übt ohne Kenntnis des Arbeitgebers eine Nebentätigkeit im gleichen Geschäftszweig aus.",
                         "Ein Mitarbeiter der DataSec IT GmbH erhält beim Ausscheiden aus der DataSec IT GmbH ein einfaches Zeugnis.",
                         "Die DataSec IT GmbH meldet einen neuen Arbeitnehmer drei Tage nach Arbeitsbeginn zur Sozialversicherung an.",
                         "Die DataSec IT GmbH hat aus betrieblichen Gründen im Monat Mai eine Urlaubssperre verhängt.",
                         "Die DataSec IT GmbH schließt aus Kostengründen die Werkskantine."],
                        "Eine nicht gemeldete Konkurrenztätigkeit verletzt die Treuepflicht des Arbeitnehmers."),
        w1920WiSoChoice("8", .arbeitsrecht, "Die Mitarbeiterin Barbara Meier, seit 16 Jahren im Betrieb, hat sich für eine Stelle in der Verkaufsabteilung beworben. Um ihre Chancen einschätzen zu können, möchte sie Einsicht in ihre Personalakte nehmen.\nWelche der folgenden Entscheidungen der Personalleiterin ist korrekt?",
                        ["Sie gewährt Frau Meier Einsicht in die Personalakte, da sie das Recht dazu hat.",
                         "Sie will Frau Meier die Einsicht in die Personalakte verweigern, da Arbeitnehmer hierauf grundsätzlich keinen Anspruch haben.",
                         "Frau Meier muss ihre Bitte über den Betriebsrat vortragen. Die Einsicht in die Personalakte darf ihr nur im Beisein eines Vertreters des Betriebsrates gewährt werden.",
                         "Sie gewährt Frau Meier keine Einsicht in die Personalakte, da dieses Recht nur dem Geschäftsführer zusteht.",
                         "Sie will Frau Meier nur dann Einsicht in die Personalakte gewähren, wenn Frau Meier ein begründetes Interesse nachweist."],
                        "Arbeitnehmer haben ein Recht auf Einsicht in ihre Personalakte (§ 83 BetrVG)."),
        w1920WiSoChoice("9", .schutz, "In der DataSec IT GmbH muss die Arbeitssicherheit gewährleistet sein.\nWelche der folgenden Aussagen trifft auf die Arbeitssicherheit in Unternehmen zu?",
                        ["Eine Unternehmung mit mehr als 20 Beschäftigten muss einen Arbeitsschutzausschuss einrichten, in dem Themen des Arbeitsschutzes erörtert werden.",
                         "Eine Mitbestimmung von Arbeitnehmern beim Arbeitsschutz ist ausgeschlossen, da das Arbeitsschutzgesetz die Pflichten der Arbeitgeber im Einzelnen regelt.",
                         "Betriebliche Arbeitsschutzbestimmungen sind kein zwingendes Recht des Arbeitsverhältnisses und Verstöße durch Mitarbeiter führen somit nicht zu arbeitsrechtlichen Konsequenzen.",
                         "Die Ergonomie von Arbeitsplätzen ist keine Anforderung der Arbeitssicherheit, sondern eine freiwillige Leistung des Arbeitgebers zur Verbesserung der Leistungsfähigkeit von Mitarbeitern.",
                         "Die regelmäßige Unterweisung der Arbeitnehmer zum betrieblichen Arbeitsschutz erfolgt durch externe Berater der Gewerkschaft als die für den Arbeitsschutz zuständige Institution."],
                        "Nach dem Arbeitssicherheitsgesetz ist ab mehr als 20 Beschäftigten ein Arbeitsschutzausschuss zu bilden."),
        w1920WiSoChoice("10", .arbeitsrecht, "Oliver Schnell, ein Mitarbeiter der DataSec IT GmbH, erkrankt während seines Urlaubs.\nWelche der folgenden Aussagen ist richtig?",
                        ["Werden die Tage der Arbeitsunfähigkeit ärztlich nachgewiesen, so erfolgt keine Anrechnung auf den Jahresurlaub.",
                         "Die Tage der Arbeitsunfähigkeit werden zur Hälfte auf den Jahresurlaub angerechnet.",
                         "Die Tage der Arbeitsunfähigkeit werden voll auf den Jahresurlaub angerechnet.",
                         "Die Arbeitsunfähigkeit wird nur dann angerechnet, wenn die Erkrankung in Deutschland auftrat.",
                         "Die Tage der Arbeitsunfähigkeit werden nur bei Krankenhausaufenthalt nicht angerechnet."],
                        "Ärztlich nachgewiesene Krankheitstage werden nicht auf den Urlaub angerechnet (§ 9 BUrlG)."),
        w1920WiSoChoice("11a", .mitbestimmung, "In der DataSec IT GmbH soll zum ersten Mal ein Betriebsrat gewählt werden.\nDerzeit sind von den Mitarbeitern in der DataSec IT GmbH länger als sechs Monate beschäftigt:\n70 Kaufmännische Mitarbeiter (alle volljährig)\n170 Technische Mitarbeiter (6 minderjährig, 164 volljährig)\n4 Auszubildende (2 minderjährig, 2 volljährig unter 25 Jahre)\n\nErmitteln Sie anhand des abgebildeten Gesetzesauszuges aus dem Betriebsverfassungsgesetz ...\na) die Anzahl der Personen, die dem Betriebsrat höchstens angehören können.\n\n§ 7 Wahlberechtigung: Wahlberechtigt sind alle Arbeitnehmer des Betriebs, die das 18. Lebensjahr vollendet haben. Werden Arbeitnehmer eines anderen Arbeitgebers zur Arbeitsleistung überlassen, so sind diese wahlberechtigt, wenn sie länger als drei Monate im Betrieb eingesetzt werden.\n§ 8 Wählbarkeit (1): Wählbar sind alle Wahlberechtigten, die sechs Monate dem Betrieb angehören oder als in Heimarbeit Beschäftigte in der Hauptsache für den Betrieb gearbeitet haben. Auf diese sechsmonatige Betriebszugehörigkeit werden Zeiten angerechnet, in denen der Arbeitnehmer unmittelbar vorher einem anderen Betrieb desselben Unternehmens oder Konzerns (§ 18 Abs. 1 des Aktiengesetzes) angehört hat. Nicht wählbar ist, wer infolge strafgerichtlicher Verurteilung die Fähigkeit, Rechte aus öffentlichen Wahlen zu erlangen, nicht besitzt.\n§ 9 Zahl der Betriebsratsmitglieder: Der Betriebsrat besteht in Betrieben mit in der Regel 5 bis 20 wahlberechtigten Arbeitnehmern aus einer Person, 21 bis 50 wahlberechtigten Arbeitnehmern aus 3 Mitgliedern, 51 bis 100 Arbeitnehmern aus 5 Mitgliedern, 101 bis 200 Arbeitnehmern aus 7 Mitgliedern, 201 bis 400 Arbeitnehmern aus 9 Mitgliedern, 401 bis 700 Arbeitnehmern aus 11 Mitgliedern, 701 bis 1.000 Arbeitnehmern aus 13 Mitgliedern, …",
                        ["9 Personen", "7 Personen", "11 Personen", "5 Personen", "13 Personen"],
                        "Wahlberechtigt sind 70 + 164 + 2 = 236 Personen; laut § 9 ergeben 201 bis 400 Arbeitnehmer einen Betriebsrat aus 9 Mitgliedern."),
        w1920WiSoChoice("11b", .mitbestimmung, "In der DataSec IT GmbH soll zum ersten Mal ein Betriebsrat gewählt werden.\nDerzeit sind von den Mitarbeitern in der DataSec IT GmbH länger als sechs Monate beschäftigt:\n70 Kaufmännische Mitarbeiter (alle volljährig)\n170 Technische Mitarbeiter (6 minderjährig, 164 volljährig)\n4 Auszubildende (2 minderjährig, 2 volljährig unter 25 Jahre)\n\nErmitteln Sie anhand des abgebildeten Gesetzesauszuges aus dem Betriebsverfassungsgesetz ...\nb) die Anzahl der wahlberechtigten Arbeitnehmer.\n\n§ 7 Wahlberechtigung: Wahlberechtigt sind alle Arbeitnehmer des Betriebs, die das 18. Lebensjahr vollendet haben. …",
                        ["236 Arbeitnehmer", "244 Arbeitnehmer", "240 Arbeitnehmer", "234 Arbeitnehmer", "170 Arbeitnehmer"],
                        "Wahlberechtigt sind nur Volljährige: 70 + 164 + 2 = 236."),
        w1920WiSoChoice("12", .mitbestimmung, "Mitarbeiter der DataSec IT GmbH wollen sich im Rahmen eines Arbeitskampfes an einem Streik beteiligen.\nIn welchem der folgenden Fälle spricht man von einem „wilden Streik“?",
                        ["Die Geschäftsleitung verweigert die Urlaubszulage; daraufhin wird die Arbeit spontan niedergelegt.",
                         "Die Tarifverhandlungen werden von der Gewerkschaft als gescheitert erklärt.",
                         "Die Arbeitgeber lehnen die Forderung nach einem 13. Monatsgehalt ab.",
                         "Schließung der Werkszugänge durch Arbeitgeber.",
                         "Nur einzelne, zu einem Arbeitgeberverband gehörende Arbeitgeber werden bestreikt."],
                        "Ein wilder Streik wird spontan und ohne Aufruf der Gewerkschaft geführt."),
        w1920WiSoChoice("13", .mitbestimmung, "Viele Mitarbeiter der DataSec IT GmbH sind Mitglied einer Gewerkschaft.\nWelche der folgenden Leistungen gewähren die Gewerkschaften ihren Mitgliedern nicht?",
                        ["Finanzielle Unterstützung bei Betriebsunfällen", "Unterstützungsleistungen bei Streiks", "Rechtsschutz bei Streitigkeiten aus dem Arbeitsverhältnis", "Bildungsmaßnahmen für Jugendliche", "Rechtsberatung bei arbeitsrechtlichen Auseinandersetzungen"],
                        "Betriebsunfälle sind über die gesetzliche Unfallversicherung (Berufsgenossenschaft) abgesichert, nicht über die Gewerkschaft."),
        w1920WiSoChoice("14", .mitbestimmung, "In einem Gespräch unter Mitarbeitern der DataSec IT GmbH fällt der Begriff „Tarifautonomie“.\nWelche der folgenden Aussagen trifft auf den Begriff „Tarifautonomie“ zu?\nTarifautonomie bedeutet ...",
                        ["Recht der Tarifpartner, in eigener Verantwortung und unabhängig vom Staat Arbeitsbedingungen zu regeln.", "Mitbestimmung im Betrieb.", "Selbstständigkeit der Arbeitsagenturen.", "wirtschaftliche Gleichberechtigung von Mann und Frau.", "Handelsbeschränkungen unter zwei Staaten."],
                        "Tarifautonomie ist die Freiheit von Gewerkschaften und Arbeitgebern, Tarifverträge ohne staatliche Einmischung auszuhandeln (Art. 9 Abs. 3 GG)."),
        w1920WiSoChoice("15", .sozial, "Die Mitarbeiter der DataSec IT GmbH diskutieren über die Möglichkeiten der privaten kapitalgestützten Altersvorsorge, weil die jüngeren Mitarbeiter befürchten, dass die zukünftige Altersrente nicht ausreichen wird.\nWelcher der folgenden wirtschaftlichen Faktoren gefährdet eine private kapitalgestützte Altersvorsorge?",
                        ["Hohe Inflationsraten", "Tariflohnerhöhungen", "Senkung der Beiträge zur gesetzlichen Rentenversicherung", "Hohe Zinsen auf Sparguthaben", "Rückgang der Arbeitslosigkeit"],
                        "Hohe Inflation entwertet angespartes Kapital und damit die spätere Rente."),
        w1920WiSoChoice("16", .sozial, "Das Prinzip der gesetzlichen Sozialversicherung ist das sogenannte Solidaritätsprinzip.\nWelche der folgenden Aussagen trifft auf diesen Grundsatz zu?",
                        ["Die Beiträge zur gesetzlichen Sozialversicherung bemessen sich nach der wirtschaftlichen Leistungsfähigkeit des Versicherten.", "Jeder muss sich zusätzlich selbst versichern.", "Arbeitgeber und Arbeitnehmer teilen sich die Beitragsleistungen.", "Die Beiträge zur Sozialversicherung sind für alle Versicherten gleich hoch.", "Eigennutz geht vor Gemeinnutz."],
                        "Solidarität heißt: Beiträge richten sich nach dem Einkommen, Leistungen nach dem Bedarf."),
        w1920WiSoChoice("17", .sozial, "Für die Angestellte Anke Heitmann müssen Beiträge zur Sozialversicherung abgeführt werden.\nIn welcher Zeile (1 bis 5) der folgenden Tabelle ist die Aufteilung der Sozialversicherungsbeiträge zwischen der DataSec IT GmbH und Frau Heitmann richtig wiedergegeben?\nVersicherung / DataSec IT GmbH / Frau Heitmann",
                        ["Zeile 4: Rentenversicherung, 50 % / 50 %", "Zeile 1: Krankenversicherung, 70 % / 30 %", "Zeile 2: Unfallversicherung, 50 % / 50 %", "Zeile 3: Arbeitslosenversicherung, 70 % / 30 %", "Zeile 5: Pflegeversicherung, 80 % / 20 %"],
                        "Renten-, Kranken-, Arbeitslosen- und Pflegeversicherung werden (im Regelfall) je zur Hälfte getragen; die Unfallversicherung zahlt allein der Arbeitgeber."),
        w1920WiSoChoice("18", .sozial, "Mitarbeiter der DataSec IT GmbH diskutieren über die Sozialversicherungen in Deutschland.\nWelche der folgenden Leistungen erbringt die Rentenversicherung?",
                        ["Erwerbsunfähigkeitsrente", "Krankengeld", "Sterbegeld", "Kurzarbeitergeld", "Mutterschaftsgeld"],
                        "Die Rentenversicherung zahlt neben Altersrenten auch Renten wegen Erwerbsminderung; Krankengeld kommt von der Krankenkasse, Kurzarbeitergeld von der Arbeitsagentur."),
        w1920WiSoChoice("19", .sozial, "Individualversicherungen unterscheiden sich von Sozialversicherungen am stärksten darin, dass Sozialversicherungen für jeden Arbeitnehmer zwingend vorgeschrieben sind.\nWelche der folgenden Aussagen trifft auf eine Individualversicherung zu?",
                        ["Eine Individualversicherung kommt durch freie vertragliche Vereinbarung zustande.", "Ihr Beitrag wird zur Hälfte vom Arbeitgeber und zur Hälfte vom Arbeitnehmer bezahlt.", "Die DataSec IT GmbH muss eine Individualversicherung haben, weil dies gesetzlich vorgeschrieben ist.", "Die Prämien einer Individualversicherung richten sich nach den Einkommensverhältnissen.", "Die Individualversicherung ist Teil der gesetzlichen Sozialversicherung."],
                        "Individualversicherungen werden freiwillig per Vertrag abgeschlossen; die Prämie richtet sich nach dem Risiko."),
        w1920WiSoChoice("20", .arbeitsrecht, "Der Geschäftsführer der DataSec IT GmbH, Christian Huf, will die Potenziale der Mitarbeiter analysieren.\nWelche der folgenden Aussagen zur Potenzialanalyse ist richtig?\nDie Potenzialanalyse ...",
                        ["dient zur Erfassung von Stärken und Schwächen der Mitarbeiter.", "muss regelmäßig durchgeführt werden.", "dient zur Erfassung der finanziellen Möglichkeiten der Mitarbeiter.", "darf nur von einem Sachverständigen der Berufsgenossenschaft durchgeführt werden.", "darf nicht in der Probezeit durchgeführt werden."],
                        "Die Potenzialanalyse ermittelt Stärken, Schwächen und Entwicklungsmöglichkeiten der Mitarbeiter."),
        .match(id: "ihk-ap2-2019w-wiso-21", topic: .unternehmen,
               prompt: "\(w1920WiSoLage)\n\n21. Aufgabe\nDie DataSec IT GmbH möchte zum Jahresende einige Kennzahlen ermitteln.\nWelche der folgenden Formeln gibt die a) Eigenkapitalrentabilität, b) Wirtschaftlichkeit, c) Produktivität wieder?\nFormeln: Gewinn × 100 / Umsatzerlöse; Ertrag / Aufwand; Ausbringungsmenge / Einsatzmenge; Gewinn × 100 / eingesetztes Eigenkapital; Kapital / Gewinn × 100; Aufwendungen × 100 / Erträge; Umsatzerlöse × 100 / Gewinn; gearbeitete Stundenzahl / erstellte Stückzahl",
               pairs: [("Eigenkapitalrentabilität", "Gewinn × 100 / eingesetztes Eigenkapital"), ("Wirtschaftlichkeit", "Ertrag / Aufwand"), ("Produktivität", "Ausbringungsmenge / Einsatzmenge")],
               extra: ["Gewinn × 100 / Umsatzerlöse", "Kapital / Gewinn × 100", "Aufwendungen × 100 / Erträge", "Umsatzerlöse × 100 / Gewinn", "Gearbeitete Stundenzahl / erstellte Stückzahl"],
               explanation: "Lösung laut Lösungshinweis (Vorläufige Lösungen): a) Formel 4, b) Formel 2, c) Formel 3. Gewinn × 100 / Umsatzerlöse wäre die Umsatzrentabilität. Quelle: IHK AP2 FiSi Winter 2019/20, WiSo, Aufgabe 21."),
        w1920WiSoChoice("22", .unternehmen, "Bei der DataSec IT GmbH werden in Abteilungsleiterbesprechungen viele unterschiedliche Zielsetzungen besprochen. Einige Ziele lassen sich gut miteinander verbinden (komplementäre Ziele). Andere Ziele schließen sich jedoch gegenseitig aus (konkurrierende Ziele).\nBei welcher der folgenden Zielpaarungen handelt es sich um konkurrierende Ziele?",
                        ["Einführung einer Betriebsrente und Reduzierung der Sozialleistungen", "Kostenminimierung und Gewinnmaximierung", "Erhöhung der Produktionsmenge und Vergrößerung der Produktionskapazitäten", "Abbau von Arbeitsplätzen und Outsourcing des Rechnungswesens", "Umsatzsteigerung und Gewinnmaximierung"],
                        "Eine Betriebsrente erhöht die Sozialleistungen, die Reduzierung senkt sie: Die Ziele schließen sich aus."),
        .match(id: "ihk-ap2-2019w-wiso-23", topic: .unternehmen,
               prompt: "\(w1920WiSoLage)\n\n23. Aufgabe\nIn der DataSec IT GmbH wird die Zusammenarbeit von Unternehmen in ihrem wirtschaftlichen Umfeld beobachtet. Die jeweilige Art der Zusammenarbeit ist an bestimmten Sachverhalten erkennbar.\nOrdnen Sie die folgenden Formen der Zusammenarbeit den nachstehenden Sachverhalten zu.\nFormen der Zusammenarbeit: Fusion; Kartell; Konzern; Arbeitsgemeinschaft",
               pairs: [("Mehrere Unternehmen führen gemeinsam einen Großauftrag aus.", "Arbeitsgemeinschaft"), ("Die EPS AG hat die Aktienmehrheit an der Tuxa AG übernommen.", "Konzern"),
                       ("Die DataSec IT GmbH vereinbart mit Wettbewerbern einheitliche Verkaufskonditionen.", "Kartell"), ("Zwei Kunden der DataSec IT GmbH, die Schmidt GmbH und die Weber KG, schließen sich zur Schmidt GmbH & Co. KG zusammen.", "Fusion")],
               extra: [],
               explanation: "Lösung laut Lösungshinweis (Vorläufige Lösungen): a) Arbeitsgemeinschaft, b) Konzern, c) Kartell, d) Fusion. Quelle: IHK AP2 FiSi Winter 2019/20, WiSo, Aufgabe 23."),
        w1920WiSoChoice("24", .unternehmen, "Die DataSec IT GmbH strebt einen Unternehmenszusammenschluss an.\nIn welchem der folgenden Fälle liegt ein horizontaler Unternehmenszusammenschluss vor?\nDie DataSec IT GmbH ...",
                        ["schließt sich mit einem regionalen Konkurrenten zusammen.", "gründet mit zwei weiteren IT-Dienstleistern eine Arbeitsgemeinschaft, um durch Synergieeffekte die Kosten zu senken.", "erwirbt die Kapitalmehrheit an einem Produzenten, um Einfluss auf dessen Produktpolitik nehmen zu können.", "übernimmt vollständig ein Unternehmen aus einem Geschäftsumfeld, in dem die DataSec IT GmbH bisher nicht vertreten ist.", "lässt sich nun auch von der Wischnewski GmbH beliefern."],
                        "Horizontal heißt: Zusammenschluss von Unternehmen derselben Wirtschaftsstufe, hier mit einem Konkurrenten."),
        w1920WiSoChoice("25", .unternehmen, "Die DataSec IT GmbH wird im Handelsregister Berlin geführt.\nWelche der folgenden Aussagen zum Handelsregister ist richtig?\nDas Handelsregister ...",
                        ["hat verschiedene Abteilungen.", "wird bei der Industrie- und Handelskammer geführt.", "erlaubt nur den geschäftsführenden Gesellschaftern Einsicht.", "ist ein Verzeichnis für alle Gewerbetreibenden.", "enthält Eintragungen über Personen mit allgemeiner Handlungsvollmacht."],
                        "Das Handelsregister (Amtsgericht) hat die Abteilungen A (Einzelunternehmen, Personengesellschaften) und B (Kapitalgesellschaften); Einsicht hat jedermann."),
        w1920WiSoChoice("26", .wirtschaft, "Für ein auch von der DataSec IT GmbH vertriebenes Produkt liegt folgende Grafik über die Marktsituation vor:\n[Abbildung als Text: Preis-Mengen-Diagramm mit der Angebotskurve und zwei Nachfragekurven, „Nachfrage II. Quartal“ und „Nachfrage III. Quartal“; die Nachfragekurve des III. Quartals liegt links der des II. Quartals; Lage der Kurven sinngemäß ergänzt.]\nWelche der folgenden Aussagen können Sie ohne zusätzliche Informationen aus der Grafik ableiten?\nIm III. Quartal ...",
                        ["ist die Nachfrage gesunken.", "wurde das Angebot vergrößert.", "wurde kein Marktgleichgewichtspreis erreicht.", "wirkte sich die höhere Nachfrage nach einem Komplementärprodukt aus.", "wurden die Werbemaßnahmen eingeschränkt."],
                        "Die Verschiebung der Nachfragekurve nach links zeigt eine gesunkene Nachfrage; Ursachen (Werbung, Komplementärgüter) lassen sich aus der Grafik nicht ableiten."),
        w1920WiSoChoice("27", .unternehmen, "Der Geschäftsführer der DataSec IT GmbH möchte den langjährigen Mitarbeiter Murat Assan zum Prokuristen ernennen.\nWelche der folgenden Aussagen ist zutreffend?",
                        ["Als Prokurist unterzeichnet Herr Assan: „ppa. Murat Assan“.", "Herr Assan darf mit Prokura Bilanzen unterzeichnen.", "Die Prokura von Herrn Assan darf im Innen- und Außenverhältnis beschränkt werden.", "Herr Assan darf mit Prokura im Bedarfsfall Grundstücke veräußern.", "Die Prokura gilt erst mit Eintrag ins Handelsregister."],
                        "Der Prokurist zeichnet mit dem Zusatz „ppa.“. Prokura wird im Außenverhältnis nicht wirksam beschränkt, Grundstücke darf er nur mit besonderer Befugnis veräußern, und der Eintrag ins Handelsregister ist nur deklaratorisch."),
        w1920WiSoChoice("28", .recht, "Einige Handlungen der DataSec IT GmbH müssen notariell beurkundet werden, damit das Rechtsgeschäft gültig wird.\nBei welcher der folgenden Handlungen muss eine notarielle Beurkundung erfolgen, damit das Rechtsgeschäft gültig wird?",
                        ["Die DataSec IT GmbH kauft ein Grundstück.", "Der Geschäftsführer der DataSec IT GmbH übernimmt eine Kreditbürgschaft für einen Geschäftsfreund.", "Die DataSec IT GmbH mietet eine Lagerhalle.", "Die DataSec IT GmbH least einen neuen Server.", "Zur Finanzierung der neuen IT-Infrastruktur wird ein Darlehen aufgenommen."],
                        "Grundstückskaufverträge brauchen die notarielle Beurkundung (§ 311b BGB)."),
        w1920WiSoChoice("29", .wirtschaft, "Ein Workshop der DataSec IT GmbH beschäftigt sich mit dem Thema Globalisierung.\nWelche der folgenden Auswirkungen trifft dabei auf deutsche Unternehmen zu?",
                        ["Die Produktionskosten können durch Verlagerung der Produktion in Länder mit niedrigeren Löhnen gesenkt werden.", "Ausländische Fachkräfte haben jederzeit Zugang zum deutschen Arbeitsmarkt und können von jedem Unternehmen sofort eingestellt werden.", "Da Deutschland ein Niedriglohnland ist, stehen jedem deutschen Unternehmen ausreichend Fachkräfte zur Verfügung.", "Alle Aufträge jedes deutschen Unternehmens werden weltweit in EUR abgewickelt.", "Durch einen Rückgang der Transporte der deutschen Unternehmen sinkt der Preis für Kraftstoffe."],
                        "Globalisierung ermöglicht Produktionsverlagerung in Niedriglohnländer."),
        w1920WiSoChoice("30", .wirtschaft, "Die DataSec IT GmbH erledigt die Softwareentwicklung in weltweiter Arbeitsteilung mit Programmierern in Deutschland, Schweden und den USA.\nWelcher der folgenden Sachverhalte ergibt sich aus der weltweiten Arbeitsteilung?",
                        ["Die weltweite Arbeitsteilung in der Softwareentwicklung erhöht die Anforderungen an die IT-Sicherheit.", "Die gegenseitige Abhängigkeit der Arbeitnehmer entfällt.", "Der Gesamtprozess der Leistungserstellung wird für den einzelnen Arbeitnehmer transparenter.", "Die weltweite Arbeitsteilung führt zu einer gerechteren Einkommensverteilung.", "Der Kommunikationsaufwand wird reduziert."],
                        "Verteilte Entwicklung über Landesgrenzen hinweg erhöht Anforderungen an Zugriffsschutz, Verschlüsselung und Datenschutz."),
    ]
}
