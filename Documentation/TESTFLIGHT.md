# TestFlight

Der Workflow `.github/workflows/testflight.yml` baut die iOS-/iPadOS-App, signiert sie automatisch und lädt sie zu TestFlight hoch. Er läuft nur manuell (Actions → TestFlight → Run workflow) und braucht keine Zertifikatsdateien im Repository.

## Einmalige Einrichtung

1. **App-Eintrag** in App Store Connect anlegen (Apps → +): Plattform iOS, Bundle-ID `de.linolaske.fisitrainer`, Name und SKU frei wählbar. Die Bundle-ID erscheint erst im Auswahlfeld, wenn sie im Developer-Portal registriert ist; Xcode legt sie beim ersten Lauf mit `-allowProvisioningUpdates` selbst an.
2. **API-Schlüssel** erzeugen: App Store Connect → Benutzer und Zugriff → Integrationen → App Store Connect API → Schlüssel erzeugen. Die Rolle muss Zertifikate und Profile verwalten dürfen (in der Regel *Admin*). Die `.p8`-Datei lässt sich nur einmal herunterladen.
3. **Repository-Secrets** anlegen (Settings → Secrets and variables → Actions):
   - `ASC_KEY_ID`: Schlüssel-ID
   - `ASC_ISSUER_ID`: Issuer-ID (oben auf der Schlüsselseite)
   - `ASC_KEY_P8`: kompletter Inhalt der `.p8`-Datei inklusive `-----BEGIN PRIVATE KEY-----`
4. In TestFlight eine interne Testgruppe mit den eigenen Apple-IDs anlegen. Interne Tester brauchen keine Beta-Prüfung durch Apple.

## Ablauf

- Die Build-Nummer ist die Nummer des Workflow-Laufs (`CURRENT_PROJECT_VERSION`), steigt also bei jedem Upload. Die Marketing-Version kommt aus dem Projekt (`MARKETING_VERSION`) oder aus dem optionalen Eingabefeld.
- Signiert wird mit `-allowProvisioningUpdates` und dem API-Schlüssel (cloud-verwaltete Zertifikate und Profile). Der Archive-Build verwendet `FiSiTrainer-iOS.entitlements` und das Flag `ICLOUD_SYNC`; der iCloud-Schalter ist deshalb nur in diesen Builds sichtbar.
- Der Export lädt direkt hoch (`destination = upload`). Nach der Verarbeitung durch Apple (einige Minuten) erscheint der Build in TestFlight.
- Das Secret-File liegt nur im temporären Runner-Verzeichnis und wird am Ende des Schritts gelöscht. Der Workflow hat nur Leserechte auf das Repository.

## Bekannte Grenzen

- Der Mac-Build ist nicht Teil davon. Er bleibt eine ad-hoc signierte DMG (siehe `Scripts/package-release.sh`), bis Developer-ID-Signierung und Notarisierung eingerichtet sind.
- Der Workflow wurde noch nicht mit echten Zugangsdaten ausgeführt. Beim ersten Lauf können Fehler zu fehlender Rolle, App-Eintrag oder Icon-Format auftreten; die Meldungen von `xcodebuild` nennen die Ursache.
