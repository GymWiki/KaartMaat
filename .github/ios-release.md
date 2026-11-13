# iOS-release: de .ipa voor de App Store maken

De actie **iOS release** bouwt Kaartmaat op een Mac van GitHub en geeft je het
bestand dat de App Store nodig heeft: een **.ipa** (te vinden onder
*Artifacts* van de run). Je uploadt die met de Apple-app **Transporter**, of je
laat de actie hem zelf naar TestFlight sturen.

## Starten

GitHub > **Actions** > **iOS release (.ipa voor de App Store)** > **Run workflow**.

- *Buildnummer*: laat leeg om het nummer achter de `+` in `pubspec.yaml` te
  gebruiken. App Store Connect weigert een buildnummer dat je al hebt gebruikt,
  dus vul bij elke nieuwe upload een hoger nummer in.
- *Meteen uploaden*: alleen aanzetten als je de drie `APP_STORE_CONNECT_…`
  secrets hieronder hebt ingesteld.

Na een paar minuten staat de .ipa (bestandsnaam met versie en buildnummer)
onder **Artifacts** onderaan de run. Download, pak de zip uit en sleep de .ipa in
Transporter (gratis, Mac App Store) of gebruik de optie hierboven.

## Eenmalig: wat je van Apple nodig hebt

Een betaald Apple Developer-account (99 dollar per jaar) en een app-record in
App Store Connect met bundle-ID `com.kaartmaat.app`.

Zet daarna in GitHub bij **Settings > Secrets and variables > Actions** deze
secrets. Alles werkt ook vanaf Windows.

| Secret | Wat |
|---|---|
| `IOS_CERTIFICATE_BASE64` | Distributiecertificaat (.p12), als base64 |
| `IOS_CERTIFICATE_PASSWORD` | Het wachtwoord dat je bij het maken van de .p12 koos |
| `IOS_PROVISIONING_PROFILE_BASE64` | App Store-profile (.mobileprovision), als base64 |
| `APP_STORE_CONNECT_KEY_ID` | Alleen voor uploaden: sleutel-ID |
| `APP_STORE_CONNECT_ISSUER_ID` | Alleen voor uploaden: issuer-ID |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Alleen voor uploaden: de .p8-sleutel, als base64 |

### Certificaat maken (zonder Mac)

1. Maak een sleutel en een aanvraag (CSR), bijvoorbeeld in Git Bash. Bewaar
   `ios.key` veilig en zet hem nooit in git:

   ```bash
   openssl genrsa -out ios.key 2048
   openssl req -new -key ios.key -out ios.csr -subj "/emailAddress=jouw@mail.nl/CN=Kaartmaat/C=NL"
   ```

2. developer.apple.com > **Certificates, IDs & Profiles** > **Certificates** >
   **+** > **Apple Distribution** > upload `ios.csr` > download `distribution.cer`.
3. Maak er een .p12 van (kies een wachtwoord):

   ```bash
   openssl x509 -inform DER -in distribution.cer -out distribution.pem
   openssl pkcs12 -export -inkey ios.key -in distribution.pem -out distribution.p12 \
     -keypbe PBE-SHA1-3DES -certpbe PBE-SHA1-3DES -macalg sha1
   ```

4. **Identifiers**: controleer dat er een App ID `com.kaartmaat.app` is, met de
   capability **In-App Purchase**.
5. **Profiles** > **+** > **App Store Connect** (distribution) > kies dat App ID
   en je Apple Distribution-certificaat > download het `.mobileprovision`.
6. Maak base64 van de bestanden (PowerShell) en plak de uitkomst in het secret:

   ```powershell
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("distribution.p12")) | Set-Clipboard
   [Convert]::ToBase64String([IO.File]::ReadAllBytes("Kaartmaat.mobileprovision")) | Set-Clipboard
   ```

### Sleutel voor uploaden (optioneel)

App Store Connect > **Users and Access** > **Integrations** > **App Store
Connect API** > **+** (rol *App Manager*) > noteer *Key ID* en *Issuer ID* en
download de `.p8` (kan maar één keer). Base64 ervan in
`APP_STORE_CONNECT_API_KEY_BASE64`.

## Wat de actie doet

1. Controleert of de secrets er zijn (anders een duidelijke foutmelding).
2. Installeert de nieuwste Xcode, Flutter 3.38.5 en je certificaat en profile
   in een tijdelijke keychain.
3. Zet alleen voor het Runner-target handmatige signering aan (alleen in de
   kopie op de runner; de projectbestanden in git blijven ongewijzigd).
4. `flutter build ipa --release` en bewaart de .ipa 30 dagen als download.
5. Uploadt optioneel naar TestFlight en ruimt de keychain en sleutels op.

Secrets komen nooit in de logs of in git terecht.

## Goed om te weten

- Elk certificaat en profile verloopt na een jaar; maak ze dan opnieuw en werk
  de secrets bij.
- App Store Connect vraagt bij elke upload naar exportconformiteit. Dat kun je
  vooraf beantwoorden door in `ios/Runner/Info.plist`
  `ITSAppUsesNonExemptEncryption` op `false` te zetten (Kaartmaat gebruikt geen
  eigen encryptie). Dat is jouw verklaring richting Apple, dus ik heb het niet
  zelf toegevoegd.
- De actie is niet getest op een echte Mac-runner: er is hier geen Apple-account
  en geen Mac. Verwacht dat de eerste run mogelijk nog een kleine aanpassing
  nodig heeft; stuur de foutmelding dan door.
