# TestFlight und Geräte-Builds

Die Entwicklung läuft lokal in Xcode auf dem Mac. TestFlight-Builds entstehen ebenfalls lokal; das ist der normale Weg und braucht weder Secrets noch Zertifikatsdateien im Repository. Die GitHub-Action `testflight.yml` ist nur eine optionale Alternative (siehe unten).

## Einmalige Einrichtung

1. **Xcode-Account:** Xcode → Einstellungen → Accounts: die Apple-ID des Entwicklerteams (`J2DU2P47XW`) anmelden. Mit Automatic Signing erzeugt Xcode Zertifikate und Profile selbst.
2. **App-Eintrag** in App Store Connect (Apps → +): Plattform iOS, Name „FiSi Trainer“, Bundle-ID `de.linolaske.fisitrainer`, SKU frei wählbar (z. B. `fisitrainer`).
3. **iCloud:** Beim ersten Signieren mit Automatic Signing aktiviert Xcode die iCloud-Fähigkeit für die App-ID selbst, weil `FiSiTrainer/FiSiTrainer-iOS.entitlements` das Entitlement `com.apple.developer.ubiquity-kvstore-identifier` enthält. Nur falls Xcode meldet, dass die App-ID die Fähigkeit nicht hat: Developer-Portal → Identifiers → `de.linolaske.fisitrainer` → **iCloud** aktivieren (die Basisoption genügt, CloudKit und Container sind nicht nötig).
4. In TestFlight eine **interne Testgruppe** mit den eigenen Apple-IDs anlegen. Interne Tester brauchen keine Beta-Prüfung durch Apple.

## Auf dem eigenen iPhone oder iPad testen

1. Gerät per Kabel (oder drahtlos) koppeln, in Xcode das Scheme **FiSiTrainer** und das Gerät als Ziel wählen, Command-R.
2. Dieser Geräte-Build trägt automatisch das Compile-Flag `ICLOUD_SYNC` und die iCloud-Entitlements. Der Schalter **Mit iCloud synchronisieren** erscheint in der Ansicht „Level“. Im Simulator, auf dem Mac und in der CI fehlt er absichtlich.
3. Für einen Sync-Test müssen beide Geräte bei derselben Apple-ID in iCloud angemeldet sein (iPhone und iPad). Der Mac kann noch nicht teilnehmen, siehe `ICLOUD-SYNC.md`.

## Build zu TestFlight hochladen

Am einfachsten per Skript, das mit dem lokalen Xcode archiviert und direkt hochlädt:

```sh
bash Scripts/testflight-local.sh          # Version aus dem Projekt
bash Scripts/testflight-local.sh 1.5.0    # optional: Marketing-Version setzen
```

Das Skript nutzt den in Xcode angemeldeten Account (`-allowProvisioningUpdates`), setzt als Build-Nummer einen UTC-Zeitstempel (`yyyymmddHHMM`, steigt also bei jedem Upload) und exportiert mit `Packaging/ExportOptions-TestFlight.plist` (`destination = upload`). Nach der Verarbeitung durch Apple (einige Minuten) erscheint der Build in TestFlight. Statt des Skripts geht auch in Xcode: Product → Archive → Distribute App → TestFlight & App Store → Distribute; dann die Build-Nummer vorher selbst erhöhen.

Wer lieber einen API-Schlüssel statt des Xcode-Accounts nutzt, setzt `ASC_KEY_PATH`, `ASC_KEY_ID` und `ASC_ISSUER_ID`; der Schlüssel braucht für das cloud-verwaltete Signieren die Rolle *Admin*.

## Optional: Upload per GitHub Actions

`.github/workflows/testflight.yml` macht dasselbe auf einem Runner (Actions → TestFlight → Run workflow). Er braucht die Repository-Secrets `ASC_KEY_ID`, `ASC_ISSUER_ID` und `ASC_KEY_P8` (Inhalt der `.p8`-Datei) und einen Schlüssel mit der Rolle **Admin**: Beim Export signiert Apple in der Cloud, ein Schlüssel mit der Rolle *App Manager* scheitert dort mit `Cloud signing permission error`. Das Repository ist öffentlich; ein Admin-Schlüssel als dauerhaftes Secret ist deshalb nur mit Bedacht zu empfehlen (am besten in einer Environment, die auf `main` beschränkt ist). Eine Variante mit manuell erzeugtem Distribution-Zertifikat und Profil als Secrets würde mit einem Upload-Schlüssel der Rolle *App Manager* auskommen, ist aber noch nicht umgesetzt.

## Bekannte Grenzen

- Der Mac-Build ist nicht Teil davon. Er bleibt eine ad-hoc signierte DMG (siehe `Scripts/package-release.sh`), bis Developer-ID-Signierung und Notarisierung eingerichtet sind.
- Der erste Archive-Lauf auf einem Runner war erfolgreich (inklusive iCloud-Entitlement); der Upload per Skript wurde noch nicht ausgeführt.
