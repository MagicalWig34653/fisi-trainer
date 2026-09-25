// SPDX-License-Identifier: AGPL-3.0-only
// Copyright (C) 2026 Lino Laske

import Foundation

/// Original practice material for the WiSo and IT exam topics.
///
/// The tasks are written for this app and follow the topics of past IHK exams; they do not
/// reproduce exam papers. Legal values reflect German law as of 2026 and are simplified
/// where a round needs a single clear answer.
enum ExamCatalog {
    static let all: [ExamCard] =
        ausbildung + arbeitsrecht + schutz +
        mitbestimmung + sozial +
        unternehmen + recht +
        wirtschaft + nachhaltigkeit +
        netze + sicherheit + systeme

    /// Answer groups for `.fact` cards. Distractors come from facts of the same group and subject.
    enum Group {
        static let zeitraum = "zeitraum"      // "2 Wochen", "6 Monate", "3 Jahre", …
        static let alter = "alter"            // "16 Jahre", "7 Jahre", …
        static let anzahl = "anzahl"          // "5", "20 Arbeitnehmer", …
        static let prozent = "prozent"        // "18,6 %", "50 %", …
        static let stelle = "stelle"          // Institutionen, Gerichte, Behörden, Gesetze
        static let betrag = "betrag"          // "25.000 €", "1 €", …
        static let itZahl = "it-zahl"         // "128 Bit", "3 Platten", …
        static let itBegriff = "it-begriff"   // "Integrität", "RAID 1", …
    }
}
