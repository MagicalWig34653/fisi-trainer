// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

enum Transport: String, Codable {
    case tcp = "TCP"
    case udp = "UDP"
}

struct PortService: Identifiable, Codable {
    let id: String
    let name: String
    let port: Int
    let transport: String
    let hint: String

    static let catalog: [PortService] = [
        .init(id: "ftp-data", name: "FTP (Daten)", port: 20, transport: Transport.tcp.rawValue, hint: "Datenkanal im aktiven FTP-Modus"),
        .init(id: "ftp", name: "FTP (Steuerung)", port: 21, transport: Transport.tcp.rawValue, hint: "Unverschlüsselte Dateiübertragung"),
        .init(id: "ssh", name: "SSH", port: 22, transport: Transport.tcp.rawValue, hint: "Verschlüsselter Fernzugriff"),
        .init(id: "telnet", name: "Telnet", port: 23, transport: Transport.tcp.rawValue, hint: "Unverschlüsselter Fernzugriff"),
        .init(id: "smtp", name: "SMTP", port: 25, transport: Transport.tcp.rawValue, hint: "E-Mail zwischen Mailservern"),
        .init(id: "dns", name: "DNS", port: 53, transport: "TCP / UDP", hint: "Namensauflösung"),
        .init(id: "dhcp", name: "DHCP (Server)", port: 67, transport: Transport.udp.rawValue, hint: "Automatische IP-Konfiguration"),
        .init(id: "dhcp-client", name: "DHCP (Client)", port: 68, transport: Transport.udp.rawValue, hint: "Antworten an DHCP-Clients"),
        .init(id: "tftp", name: "TFTP", port: 69, transport: Transport.udp.rawValue, hint: "Einfache Dateiübertragung"),
        .init(id: "http", name: "HTTP", port: 80, transport: Transport.tcp.rawValue, hint: "Unverschlüsselte Webseiten"),
        .init(id: "kerberos", name: "Kerberos", port: 88, transport: "TCP / UDP", hint: "Tickets für die Netzwerkanmeldung"),
        .init(id: "pop3", name: "POP3", port: 110, transport: Transport.tcp.rawValue, hint: "E-Mails abrufen"),
        .init(id: "rpcbind", name: "RPCbind", port: 111, transport: "TCP / UDP", hint: "RPC-Dienste zu Ports zuordnen"),
        .init(id: "ntp", name: "NTP", port: 123, transport: Transport.udp.rawValue, hint: "Uhrzeit synchronisieren"),
        .init(id: "netbios-ns", name: "NetBIOS-Namensdienst", port: 137, transport: Transport.udp.rawValue, hint: "NetBIOS-Namen auflösen"),
        .init(id: "netbios-ssn", name: "NetBIOS-Sitzungsdienst", port: 139, transport: Transport.tcp.rawValue, hint: "Ältere Windows-Dateifreigaben"),
        .init(id: "imap", name: "IMAP", port: 143, transport: Transport.tcp.rawValue, hint: "E-Mails auf dem Server verwalten"),
        .init(id: "snmp", name: "SNMP", port: 161, transport: Transport.udp.rawValue, hint: "Netzwerkgeräte überwachen"),
        .init(id: "snmptrap", name: "SNMP-Trap", port: 162, transport: Transport.udp.rawValue, hint: "Ereignismeldungen von Netzwerkgeräten"),
        .init(id: "bgp", name: "BGP", port: 179, transport: Transport.tcp.rawValue, hint: "Routing zwischen autonomen Systemen"),
        .init(id: "ldap", name: "LDAP", port: 389, transport: Transport.tcp.rawValue, hint: "Verzeichnisdienst abfragen"),
        .init(id: "https", name: "HTTPS", port: 443, transport: "TCP / UDP", hint: "Verschlüsselte Webseiten; HTTP/3 nutzt UDP"),
        .init(id: "smb", name: "SMB", port: 445, transport: Transport.tcp.rawValue, hint: "Windows-Dateifreigaben"),
        .init(id: "submissions", name: "SMTPS", port: 465, transport: Transport.tcp.rawValue, hint: "E-Mail-Einlieferung mit sofortiger TLS-Verschlüsselung"),
        .init(id: "ike", name: "IKE", port: 500, transport: Transport.udp.rawValue, hint: "Schlüsselaustausch für IPsec"),
        .init(id: "syslog", name: "Syslog (klassisch)", port: 514, transport: Transport.udp.rawValue, hint: "Klassische Protokollmeldungen ohne TLS"),
        .init(id: "submission", name: "SMTP Submission", port: 587, transport: Transport.tcp.rawValue, hint: "E-Mails beim Mailserver einliefern"),
        .init(id: "ipp", name: "IPP", port: 631, transport: Transport.tcp.rawValue, hint: "Druckaufträge über das Netzwerk"),
        .init(id: "ldaps", name: "LDAPS", port: 636, transport: Transport.tcp.rawValue, hint: "Verschlüsselter Verzeichnisdienst"),
        .init(id: "imaps", name: "IMAPS", port: 993, transport: Transport.tcp.rawValue, hint: "Verschlüsselter IMAP-Abruf"),
        .init(id: "pop3s", name: "POP3S", port: 995, transport: Transport.tcp.rawValue, hint: "Verschlüsselter POP3-Abruf"),
        .init(id: "mssql", name: "Microsoft SQL Server", port: 1433, transport: Transport.tcp.rawValue, hint: "SQL-Server-Datenbankverbindung"),
        .init(id: "l2tp", name: "L2TP", port: 1701, transport: Transport.udp.rawValue, hint: "VPN-Tunnelprotokoll"),
        .init(id: "radius", name: "RADIUS (Authentifizierung)", port: 1812, transport: Transport.udp.rawValue, hint: "Zentrale Netzwerkanmeldung"),
        .init(id: "nfs", name: "NFS", port: 2049, transport: "TCP / UDP", hint: "Dateifreigaben unter Unix/Linux"),
        .init(id: "mysql", name: "MySQL", port: 3306, transport: Transport.tcp.rawValue, hint: "MySQL-Datenbank"),
        .init(id: "rdp", name: "RDP", port: 3389, transport: "TCP / UDP", hint: "Windows-Remotedesktop"),
        .init(id: "sip", name: "SIP", port: 5060, transport: "TCP / UDP", hint: "Signalisierung für IP-Telefonie"),
        .init(id: "postgresql", name: "PostgreSQL", port: 5432, transport: Transport.tcp.rawValue, hint: "PostgreSQL-Datenbank"),
        .init(id: "vnc", name: "VNC", port: 5900, transport: Transport.tcp.rawValue, hint: "Grafischer Fernzugriff")
    ]
}

enum QuestionKind: String, Codable, CaseIterable {
    case port
    case service
    case transport
}

struct Question: Codable {
    let service: PortService
    let choices: [Int]
    let correctAnswer: Int
    let questionKind: QuestionKind?
    let labels: [String]?

    init(service: PortService, choices: [Int], correctAnswer: Int,
         questionKind: QuestionKind? = nil, labels: [String]? = nil) {
        self.service = service
        self.choices = choices
        self.correctAnswer = correctAnswer
        self.questionKind = questionKind
        self.labels = labels
    }

    var kind: QuestionKind { questionKind ?? .port }

    var title: String {
        kind == .service ? "Port \(service.port)" : service.name
    }

    var prompt: String {
        switch kind {
        case .port: "Welcher Port gehört zu diesem Dienst?"
        case .service: "Welcher Dienst gehört zu diesem Port?"
        case .transport: "Welche Transportprotokolle werden üblicherweise genutzt?"
        }
    }

    var context: String {
        kind == .transport ? "Port \(service.port)" : service.transport
    }

    func answerLabel(_ choice: Int) -> String {
        guard let index = choices.firstIndex(of: choice),
              let labels, labels.indices.contains(index) else { return String(choice) }
        return labels[index]
    }

    var isValid: Bool {
        guard (1...65535).contains(service.port),
              choices.contains(correctAnswer),
              Set(choices).count == choices.count,
              labels == nil || (labels?.count == choices.count && labels?.allSatisfy { !$0.isEmpty } == true)
        else { return false }

        switch kind {
        case .port:
            return correctAnswer == service.port && choices.count == 4 &&
                choices.allSatisfy { (1...65535).contains($0) }
        case .service:
            return correctAnswer == service.port && choices.count == 4 &&
                choices.allSatisfy { (1...65535).contains($0) } && labels != nil
        case .transport:
            let expectedAnswer: Int
            switch service.transport {
            case Transport.tcp.rawValue: expectedAnswer = 0
            case Transport.udp.rawValue: expectedAnswer = 1
            case "TCP / UDP": expectedAnswer = 2
            default: return false
            }
            return choices.count == 3 && Set(choices) == Set([0, 1, 2]) &&
                correctAnswer == expectedAnswer && labels != nil
        }
    }
}

struct GameSession: Codable {
    let questions: [Question]
    var index: Int = 0
    var selectedAnswer: Int? = nil
    var score: Int = 0
    var correctCount: Int = 0
    var streak: Int = 0
    var timing: QuestionTiming? = nil
    var speedBonusTotal: Int? = nil

    var isComplete: Bool { index >= questions.count }
}

struct PlayerProgress: Codable {
    var totalXP: Int = 0
    var completedRounds: Int = 0
    var bestScore: Int = 0
    var correctAnswers: Int = 0
    var answeredQuestions: Int = 0

    var level: Int { 1 + totalXP / 250 }
}
