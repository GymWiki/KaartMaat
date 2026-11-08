# Kaartmaat QA-rapport (branch `test/full-qa`)

Datum: 2026-11-08. Basis: `main` op `3bc8da4`. In deze ronde zijn **alleen tests en dit rapport** toegevoegd; er is niets aan de app of de regels veranderd.
Volledige suite: **502 tests groen** (279 bestaand + 223 nieuw), `flutter analyze` schoon.

Wat ik wel en niet kon doen:
- Echte app op de Android-emulator (Medium Phone API 36.1): debug- en release-build geïnstalleerd, bedienen via adb en mobile-mcp, database uitgelezen. Hiermee zijn de blockers QA-02 en QA-02b en finding QA-01 **op een echt toestel-profiel bevestigd**.
- Geen `integration_test` en geen FlutterPilot: `integration_test` vereist een nieuwe dev-dependency (niet zonder jouw akkoord). In plaats daarvan draaien de flowtests de echte app (router, schermen, providers) in een widgettest met een in-memory database.
- Beperking: in widgettests komen Drift-stream-updates niet door naar de UI. Flows die live stream-updates nodig hebben (tikken in de teller, rondes bijwerken) zijn daarom op de emulator gecontroleerd, niet in de widgettests.
- **Niet gedaan / niet gemeten** (zie sectie 6): frameprestaties (gfxinfo gaf 0 frames), rotatie midden in invoer, telefoontje/low-memory-kill, OLED-contrast op echt scherm, haptics, vibratie, "keep screen on", delen via de Android-deelsheet.

## 1. Samenvatting

| Gebied | Tests toegevoegd | Resultaat |
|---|---|---|
| Statische controle (analyze, format, TODO, netwerk) | – | analyze schoon; format: 78 van 111 bestanden wijken af (QA-13) |
| Regels per spel, uitgewerkte voorbeelden (`rules_worked_examples_test`) | 98 | 98 pass |
| Data en persistentie (`persistence_test`) | 33 | 33 pass (incl. v1→v3 en v2→v3 migratie, herstart, 500 spellen) |
| Echte-app flows (`app_flows_test`) | 7 testdefinities, 13 gevallen (limieten per spel) | 13 pass |
| Layout-matrix 8 spellen × 7 schermen/lettergroottes (`layout_matrix_test`) | 56 | 8 baseline-cellen pass, **26 cellen met overflow** (QA-09, rapport-only) |
| Toegankelijkheid per paneel (`a11y_test`) | 16 | 46/48 checks pass, 2 fail (QA-11) |
| Findings vastgelegd als karakteriseringstests (`findings_test`) | 7 | 7 pass (huidig gedrag vastgepind) |
| Emulator (handmatig bediend) | – | 3 bevestigde bugs, opstarttijd gemeten |

Dekking (`flutter test --coverage`): **61% regels totaal** (4496/7338). Regelklassen: boerenbridge, klaverjas, rikken, toepen, jokeren, canasta, custom, amounts, registry **100%**; hearts 96% (74 regels, 3 gemist); game_rules 95%.

## 2. Bevindingen (op ernst)

### Blocker

**QA-02 — Snel tikken maakt dubbele rondes (stand klopt niet meer)**
- Spel/gebied: alle live-teller-spellen (Algemene teller, Toepen); dezelfde code geldt voor "bevestigen" in alle paneelspellen.
- Reproductie (emulator, bevestigd): Algemene teller met Anna en Bas, drie snelle tikken (~100 ms) op Anna's tegel. Database daarna: ronde 1 = 1 punt, ronde 2 = 2 punten, ronde 3 = 3 punten. Elke tik maakte een nieuwe ronde met het lopende totaal, dus Anna staat op **6 in plaats van 3**. Twee tikken met 1,5 s ertussen werkten wel goed (ronde 3: 3 → 5).
- Verwacht: één ronde die bijgewerkt wordt. Werkelijk: per snelle tik een nieuwe ronde.
- Oorzaak: `lib/features/games/ui/game_screen.dart` `_savePanelRound` kiest tussen `addRound` en `updateRound` op basis van `ref.read(gameStateProvider(...)).value`. Dat is de gestreamde staat en loopt achter op de database. Er is nergens een guard tegen dubbele aanroepen (grep op `_busy`/`_saving`: geen).
- Voorstel: maak opslaan een upsert in `GameRepository` (in één transactie: bestaat ronde `number` → update, anders insert) en serialiseer de aanroepen; schakel de bevestigknop uit zolang het opslaan loopt. Regressietest: twee `onSave` zonder await ertussen geven één ronde.
- Niet apart op een toestel getest: dubbel tikken op "Ronde opslaan" in de klassieke paneelspellen (zelfde functie, dus zeer waarschijnlijk hetzelfde).

### Major

**QA-02b — Dubbel tikken op "Start spel" maakt twee spellen**
- Reproductie (emulator, bevestigd): twee spelers kiezen, twee keer snel op Start tikken: database bevat spel 1 en 2, beide ongefinisht en beide zonder rondes.
- Oorzaak: `lib/features/games/ui/new_game_screen.dart` rond regel 160: `createGame` wordt gewacht zonder guard; de knop blijft actief.
- Voorstel: knop direct uitschakelen na de eerste tik (state `_starting`).

**QA-01 — Andere onafgemaakte spellen zijn onbereikbaar**
- Reproductie (emulator en `findings_test`): twee onafgemaakte spellen. Home toont één "Hervat spel"-kaart (het nieuwste); Historie toont alleen afgeronde spellen. Het oudere spel is daarna niet meer te openen of te verwijderen (en telt nooit mee).
- Dit raakt de belofte "nooit state verliezen". Gevolg van QA-02b: elk dubbel starten laat een spook-spel achter.
- Voorstel: lijst "Lopende spellen" op home of in Historie, met openen en verwijderen.

**QA-09 — Layout breekt bij 200% lettergrootte; op kleine of liggende schermen scrolt het paneel**
- Zie `docs/qa-layout-matrix.txt` (56 cellen). Samengevat:
  - 200% lettergrootte, elk schermformaat: `RenderFlex overflowed` bij Boerenbridge (26 px onder), Canasta (26), Hartenjagen (26), Jokeren (26), Toepen (51), Algemene teller (51), en Klaverjassen (169 px rechts op 411 dp, 220 px op 360 dp).
  - 100% lettergrootte op 360×640: het paneel moet 30–185 dp binnenin scrollen (Boerenbridge 7p 33, Canasta 30, Algemene teller 8p 182, Hartenjagen 6p 96, Jokeren 8p 94, Klaverjassen 87, Rikken 76).
  - Liggend (914×411): 103–297 dp scrollt binnenin.
  - Normaal toestel (411×914) @100%: alles past, behalve **Algemene teller met 8 spelers: 45 dp scrollt** (panel_fit_test dekt alleen 4 en 6 spelers).
- Oorzaak (vermoed): vaste hoogtes in de tegels en actierijen (`counter_panel.dart`, `toepen_panel.dart`, `calculator_panel.dart`, `klaverjas_panel.dart`).
- Voorstel: hoogtes laten meegroeien met `MediaQuery.textScalerOf`, en voor klein/liggend een compactere variant.

**QA-10 — Standaard Flutter-icoon**
- `android/app/src/main/res/mipmap-*/ic_launcher.png` zijn de standaard Flutter-iconen (hdpi: 544 bytes); op de emulator ook de opstart-splash met het Flutter-logo. Moet vervangen voor Play Store. Geen code-risico.

### Minor

**QA-03 — Toepen: totalen kunnen boven de uitvalgrens uitkomen na corrigeren van een eerdere ronde.** Ronde 1: 4, 5, 1 punten (totaal 10, uit). Ronde 1 corrigeren naar 8: totaal 14. De "geen punten meer na uit"-regel geldt alleen voor live tikken in de UI, niet in `ToepenRules` (alleen de oude klop-rondes nullen uitgevallen spelers). Voorstel: punten van uitgevallen spelers in `roundScores` afkappen of negeren. Dit is ook een regelvraag (zie 3).

**QA-04 — Klaverjassen: onmogelijke roem-aantallen worden geaccepteerd** (`validateRound` laat 0–8 toe voor stuk en vier boeren; 8 stukken + 8× vier boeren geeft 1860 punten voor één gift). Voorstel: stuk 0–1, vier boeren 0–1, vier gelijken 0–7.

**QA-05 — Hartenjagen: instelling "strafpunten Schoppen Vrouw" mag groter zijn dan het rondetotaal** (queen 40, totaal 10 geeft −30 harten; de invoer kan dan nooit afgerond worden). Voorstel: `queenPoints` begrenzen op `totalPoints`.

**QA-06 — Rikken: onbekende rol wordt geaccepteerd.** Een speler met een andere rol dan `bidder`/`partner`/`opp` betaalt stilletjes niets (bieder krijgt 40 in plaats van 60). Alleen bereikbaar als de UI ooit een verkeerde rol schrijft, maar `validateRound` zou dit moeten weigeren.

**QA-11 — Tekstcontrast (WCAG) in Boerenbridge-paneel faalt** (licht en donker) op een `isInMutuallyExclusiveGroup`-element rechtsboven in het paneel (de stapkeuze Biedingen/Slagen). Alle andere panelen halen contrast, tikdoelen (48 dp) en labels.

**QA-12 — Dode code en verouderde commentaren.** Alle 8 spellen hebben een `panelBuilder`, dus de klassieke invoerschermen zijn niet meer bereikbaar: `round_entry_screen.dart`, `boerenbridge_entry.dart`, `klaverjas_entry.dart`, `rikken_entry.dart`, `hearts_entry.dart`, `points_entry.dart`, `calculator_entry.dart` en de headers (≈ 700 regels op 0% dekking, plus `entryBuilder` in de registry en de route `/game/:id/round/:number`). Commentaar in `game_screen_scaffold.dart:29,33` noemt nog de "undo snackbar".

**QA-13 — Formattering.** `dart format` wijzigt 78 van 111 bestanden in `lib` en `test`. Als dat bedoeld is voor CLAUDE.md-afspraken: één aparte formatteer-commit.

**QA-14 — Onder de 70% dekking:** `settings_screen` 2%, `stats_screen` 2%, `groups_tab` 5%, `group_edit_screen` 2%, `game_screen` 47%, `dialogs` 54%, `filter_bar` 59%, `games_registry` 66% (de dode invoerschermen niet meegerekend).

### Cosmetisch / te verifiëren
- **QA-15** Spelersnamen zijn beperkt tot 24 tekens in de UI (`maxLength: 24`); de deelafbeelding kapt namen af met "…" (teamnamen "A & B" kunnen 51 tekens zijn). Bedoeld gedrag, wel handmatig bekijken (checklist).
- **QA-16** Op de emulator meldt het toegankelijkheidsoverzicht de "Speler toevoegen"-knop (FAB op het Spelers-scherm) zonder label. Controleren met TalkBack.

## 3. Open vragen over regels (graag antwoord)

1. **Rik beter ontbreekt**: er is "rik" (8 slagen met maat) en "troela" (ook 8), maar geen "rik beter" (9 slagen met maat). Moet die erbij? En klopt "8 alleen" (`alone8`) als aparte bod? (`QA-07`, `rikContracts`)
2. **Amsterdams en Rotterdams** rekenen nu identiek (de variant is alleen opgeslagen). Moet Rotterdams iets anders scoren (bijv. wat telt als nat bij 81–81, of roem)? (`QA-08`)
3. **Toepen na het corrigeren van een eerdere ronde (QA-03)**: moeten punten die een speler pas na zijn uitvallen kreeg, vervallen? En: is de standaard uitvalgrens 10 (Pagat) of 15 (nl.wikipedia)? Nu 10, instelbaar.
4. **Klaverjassen nat bij 81–81**: nu nat (`tieIsNat`, standaard aan). Bevestig dat dit je afspraak is, en dat roem van beide teams bij nat naar de tegenpartij gaat (nu zo).
5. **Hartenjagen, de maan**: standaard krijgen de anderen 26 en de schutter 0 (alternatief: schutter −26). Bevestig de standaard.
6. **Rikken, maat betaalt bij verlies**: standaard betaalt alleen de bieder dubbel; maat 0 (instelling `maatPaysWhenLost`). Bevestig de standaard en de bedragen (CardgamesHub: rik 10, piek 15, 9 alleen 20, misère 25, 10 alleen 30, open piek 40, 11 alleen 40, open misère 50, 12 alleen 50, 13 alleen 70, slam-bonus 35).
7. **Boerenbridge**: standaard 10 + 5 per slag bij exact; 5 per slag verschil af; verboden bod voor de deler aan. Bevestig. Max kaarten = ⌊52 / spelers⌋ (3 spelers 17, 7 spelers 7).

## 4. Regelafwijkingen (code tegenover bevestigde regels)

In de repository staat **geen** document met jouw eerder bevestigde Nederlandse regelsamenvatting (`git log` en `docs` bevatten er geen; die stonden alleen in het gesprek). Ik kan daarom niet vaststellen dat code en bevestigde regels afwijken, alleen dat de code consistent is met de bronnen die in de code staan (Pagat, nl.wikipedia, NKF, CardgamesHub). Alle uitgewerkte voorbeelden staan in `test/qa/rules_worked_examples_test.dart`; de bedragen daarin zijn met de hand uit de regels afgeleid. Controleer vooral:

- Boerenbridge: 4 spelers ronde 5 (5 kaarten), biedingen 2,1,0,1 en slagen 2,0,1,2 geeft 20, −5, −5, −5. Bod 5 met 0 slagen: −25. Speler-/ronde-reeks: 3 sp. 17 kaarten (33 rondes), 4 sp. 13 (25), 5 sp. 10 (19), 6 sp. 8 (15), 7 sp. 7 (13).
- Klaverjassen: 100–62 geeft 100/62; 60–102 is nat (0 / 162); 81–81 nat (of 81/81 als `tieIsNat` uit); 70 + 20 roem tegen 92 is nat, de tegenpartij krijgt 182; pit met 20 roem: 162 + 20 + 100 = 282.
- Rikken: rik 8 slagen +10/+10/−10/−10; 10 slagen 20; 7 slagen (verloren) bieder −30, maat 0, tegenpartij +15 elk; 13 slagen 70 (10 + 25 + 35); 9 alleen gehaald: bieder +60 (−20 elk); piek 1 slag: +45; misère 0 slagen: +75; 13 alleen: +210. Alle 14 contracten × 0–13 slagen zijn nul-som.
- Hartenjagen: 5/8/0/13 telt op tot 26; de maan geeft 0/26/26/26 (of −26/0/0/0); einde bij 100 (99 nog niet).
- Toepen: grens 10: 9 is "op pelt", 10 is uit; speelt door tot één speler over is (of eerste uit bij `playOn` uit).
- Jokeren: joker 25 + aas 11 + plaatje 10 = 46. Canasta: 500 + 300 + 100 − 45 = 855; einde vanaf 5000; eerste-meld-minimum: <0: 15, 0–1499: 50, 1500–2999: 90, ≥3000: 120.

## 5. Dekking en niet-geteste risicogebieden

- Totaal 61% regels. Zie QA-14 voor bestanden onder 70%.
- Niet geautomatiseerd getest: instellingen-scherm (thema, trillen, alles wissen), statistiekenscherm en filterbalk, groep aanmaken/bewerken via de UI, deelafbeelding per spel met 2 en 8 spelers en lange namen (alleen de bestaande test voor de kaart zelf), rotatie en levenscyclus, OLED-thema, "scherm aan houden".
- Gemeten: opstarttijd release op de emulator 3,4 s (eerste start na installatie), daarna 1,3–1,7 s. Debug-build eerste start ≈ 15 s (niet representatief). Frame-prestaties: niet gemeten (gfxinfo toonde 0 frames).
- Geen netwerktoegang: de release-manifest vraagt geen `INTERNET`-permissie aan (alleen debug/profile hebben die); in de code komt geen http/socket/dio voor. Op het toestel zijn geen machtigingen aangevraagd. Er zijn geen netwerkaanroepen.
- Database: schemaversie 3 (migraties v1→v3 en v2→v3 getest, inclusief behoud van spelers, spellen, rondes, groepen). Totalen worden nergens opgeslagen (getest op kolomnamen). 500 spellen (4 spelers, 10 rondes): laden 369 ms, statistieken 46 ms op de pc; 50 rondes in één spel afgeleid in < 100 ms.
- Spelers verwijderen houdt de geschiedenis intact (zachte verwijdering); hernoemen werkt ook in oude spellen door; dezelfde speler dubbel in één spel wordt door de database geweigerd en laat geen halve spelrij achter.
- Statistieken: lege data, jaargrens (31 dec 23:59 / 1 jan 00:00), gelijke stand en nulwinsten zijn getest en kloppen. Een gelijkspel telt voor alle winnaars als winst (bedoeld gedrag?).

## 6. UX-meting (aantal tikken)

Geschat uit de panelen en bestaande tests, **niet op een toestel gemeten** (zie checklist). Een normale ronde en een bijzondere ronde:

| Spel | Normale ronde | Bijzondere ronde |
|---|---|---|
| Algemene teller | 1 tik per punt/stap + "Volgende ronde" | – |
| Toepen | 1 tik per punt + "Volgende ronde" | op pelt / uit: geen extra tik |
| Boerenbridge (4 sp.) | 4 biedingen + "Naar slagen" + 3 slagen (laatste automatisch) + "Ronde afronden" = 9 | verboden bod van de deler is geblokkeerd, geen extra tikken |
| Klaverjassen | spelende partij vooringevuld (0–1), kaartpunten typen (2–3 cijfers, andere partij automatisch), bevestigen: ± 4–5 | roem: +1 paginawissel +1 per roem; pit: +1; nat: afgeleid, geen tik |
| Rikken | bieder, contract, maat (bij rik), gehaald/niet, over-/onderslagen, opslaan: ± 5–7 | piek/misère: geen overslagen |
| Hartenjagen | harten per speler (laatste automatisch), Schoppen Vrouw-houder, opslaan | maan: 1 tik + opslaan |
| Jokeren/Canasta | per speler snelknoppen of cijfers + "+" ; ± 2–4 per speler | – |

Plekken waar de gebruiker het hoofdscherm moet verlaten, iets moet typen dat de app kon afleiden, of ergens anders moet kijken: niet gevonden in de code (alles zit in het paneel); de scorebalk staat bovenaan. Wel: bij 8 spelers in de Algemene teller scrolt het paneel (QA-09), en de lopende teller maakt bij snel tikken fouten (QA-02).

## 7. Robuustheid en bijzonderheden

- Dubbel tikken: bevestigd fout bij Start spel (QA-02b) en bij snelle tikken in de live teller (QA-02). Er is nergens een re-entrancy-guard.
- Offline: zie sectie 5. Alle schermen werken zonder netwerk.
- Uitzonderingen in logs: tijdens de emulator-flows verscheen in logcat een native crash van `libbluetooth_jni` (systeemproces van de emulator, niet de app); geen `flutter:E`-regels van Kaartmaat.
- De toegankelijkheidscontrole faalt op QA-11 (contrast) en meldt geen ontbrekende labels of te kleine tikdoelen in de panelen.
- Een per ongeluk gedraaide `dart format` herschreef 78 bestanden; die wijziging is teruggezet via `git stash` (stash `qa: accidental dart format run`). Hij staat nog in de stash; verwijderen kan met `git stash drop`.

## 8. Handmatige testchecklist voor op je telefoon

Algemeen
- [ ] App start binnen ± 2 s en toont "Kaartmaat" met jouw icoon (nu: standaard Flutter-icoon).
- [ ] Alles werkt in vliegtuigmodus.
- [ ] Draai het toestel tijdens invoer: niets gaat verloren, geen afgekapte knoppen.
- [ ] Zet systeemlettertype op groot en maximaal: bij welke spellen loopt de layout uit? (QA-09)
- [ ] Bel jezelf midden in een ronde, kom terug: halve invoer is er nog.
- [ ] Sluit de app met de recente-appsknop midden in een ronde, open opnieuw: "Hervat spel" brengt je terug zonder verlies of dubbele ronde.
- [ ] Licht, donker en OLED-thema in een donkere kamer: groene accenten en alle tekst goed leesbaar.
- [ ] Trillen aan/uit: voelt het goed, niet te sterk?
- [ ] Scherm blijft aan tijdens een spel; gaat weer uit erna.
- [ ] TalkBack: iedere knop wordt voorgelezen (vooral "Speler toevoegen", ongedaan maken, min-knoppen); "Ronde N opgeslagen" wordt aangekondigd.

Algemene teller / Toepen
- [ ] Snel achter elkaar op één naam tikken (5× in 1 s): totaal klopt (QA-02!).
- [ ] Duimbereik met één hand: tegels, min-knop, "Volgende ronde".
- [ ] 8 spelers: past het paneel, hoef je te scrollen?
- [ ] Toepen: "op pelt" duidelijk zichtbaar; uit = grijs; winnaar herkenbaar.
- [ ] Groene "+1" bij "Volgende ronde": niet te groot of te opvallend.

Boerenbridge
- [ ] Bieden en slagen met 4–7 spelers: past het scherm, geen scrollen.
- [ ] Verboden bod van de deler is uitgeschakeld en duidelijk.
- [ ] Tussendoor afsluiten tussen bieden en slagen, heropenen.
- [ ] Hoeveel seconden kost een ronde? Meet er een.

Klaverjassen
- [ ] Spelende partij vooringevuld klopt (voorhand).
- [ ] Kaartpunten typen met cijfers (geen toetsenbord dat de standen afdekt).
- [ ] Roem-pagina, nat en pit: duidelijke weergave in de tabel.
- [ ] Wij/Zij-namen met lange spelersnamen.

Rikken
- [ ] Bieder, contract, maat, uitslag: aantal tikken acceptabel.
- [ ] Nul-som toont "0" na opslaan.
- [ ] Ontbreken er biedingen (zoals "rik beter")? (open vraag 1)

Hartenjagen
- [ ] Hartenaantallen en Schoppen Vrouw invoeren, maan schieten.
- [ ] Het spel stopt bij 100 en de laagste wint.

Jokeren / Canasta
- [ ] Snelknoppen en cijfers; één bedrag ongedaan maken.
- [ ] Teamnamen en doelscore 5000.

Delen en historie
- [ ] Deelafbeelding: lange namen (24 tekens), 2 en 8 spelers: tekst past, kroon en ezel bij de juiste spelers, watermerk aanwezig.
- [ ] Historie en statistieken met veel spellen: scrollen soepel.
- [ ] Kaartkoning van het jaar bij gelijke stand.
- [ ] Een spel starten en dubbel op "Start spel" tikken, daarna Historie bekijken: geen spook-spellen (QA-01, QA-02b).
