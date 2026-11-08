// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Kaartmaat';

  @override
  String get navGames => 'Spellen';

  @override
  String get navPlayers => 'Spelers';

  @override
  String get navHistory => 'Historie';

  @override
  String get navStats => 'Statistieken';

  @override
  String get navSettings => 'Instellingen';

  @override
  String get gameCustom => 'Algemene teller';

  @override
  String get gameCustomDesc => 'Pesten, Ezelen en andere spellen';

  @override
  String get gameBoerenbridge => 'Boerenbridge';

  @override
  String get gameKlaverjassen => 'Klaverjassen';

  @override
  String get gameToepen => 'Toepen';

  @override
  String get gameRikken => 'Rikken';

  @override
  String get gameHartenjagen => 'Hartenjagen';

  @override
  String get comingSoon => 'Binnenkort';

  @override
  String get otherRunningGames => 'Andere lopende spellen';

  @override
  String get settingEndMode => 'Het spel eindigt';

  @override
  String get endModeHands => 'Na een aantal giffen';

  @override
  String get endModeTarget => 'Bij een streefscore';

  @override
  String get settingTargetInclusive =>
      'Streefscore zelf telt mee (5000 of meer)';

  @override
  String get sharedWin => 'Gedeelde winst';

  @override
  String roundsPlayed(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondes gespeeld',
      one: '1 ronde gespeeld',
    );
    return '$_temp0';
  }

  @override
  String shareCaption(String game, String winner, int points) {
    return 'Uitslag $game: $winner wint met $points punten';
  }

  @override
  String shareCaptionTie(String game, String winner, int points) {
    return 'Uitslag $game: gedeelde winst voor $winner met $points punten';
  }

  @override
  String get shareAction => 'Delen';

  @override
  String get saveImage => 'Opslaan als afbeelding';

  @override
  String get imageSaved => 'Afbeelding opgeslagen in de galerij';

  @override
  String get imageSaveDenied => 'Geen toegang om de afbeelding op te slaan';

  @override
  String get imageSaveFailed => 'Opslaan is niet gelukt';

  @override
  String get shareFailed => 'Delen is niet gelukt';

  @override
  String get newGameAgain => 'Nieuw spel';

  @override
  String get resumeFinished => 'Hervat spel';

  @override
  String get resumeFinishedConfirm =>
      'Het spel weer openen om verder te spelen of te corrigeren?';

  @override
  String get closeResult => 'Sluiten';

  @override
  String get gameDuizenden => 'Duizenden';

  @override
  String get gameDuizendenDesc => 'Als eerste naar 1000 punten';

  @override
  String get duizendenHint =>
      'Wie als eerste de doelscore haalt (standaard 1000) wint. Een score per ronde mag negatief zijn. Het spel eindigt aan het einde van een ronde: halen meer spelers de doelscore, dan wint de hoogste stand.';

  @override
  String get settingMinEntry => 'Laagste score per ronde';

  @override
  String get settingMaxEntry => 'Hoogste score per ronde';

  @override
  String duizendenToGo(int points) {
    return 'nog $points';
  }

  @override
  String get duizendenReached => 'doel bereikt';

  @override
  String duizendenOutOfRange(int min, int max) {
    return 'Score buiten $min tot $max';
  }

  @override
  String duizendenReaches(String names) {
    return '$names haalt de doelscore';
  }

  @override
  String get duizendenFillAll => 'Vul de score van alle spelers in';

  @override
  String get variantGronings => 'Gronings';

  @override
  String get variantHintAmsterdams =>
      'Gewoon klaverjassen: de spelende partij moet meer punten halen dan de tegenpartij.';

  @override
  String get variantHintRotterdams =>
      'Rekent in de app hetzelfde als Amsterdams.';

  @override
  String get variantHintGronings =>
      'Eerst bieden: de spelende partij moet haar bod halen (met roem). Troeven is verplicht; overtroeven niet als de slag al van je maat is.';

  @override
  String get settingMinBid => 'Laagste bod';

  @override
  String get settingMaxBid => 'Hoogste bod';

  @override
  String get groningsBidTitle => 'Bieden';

  @override
  String get groningsPass => 'Iedereen past';

  @override
  String groningsForced(String name, int bid) {
    return '$name moet $bid bieden';
  }

  @override
  String get groningsToTrump => 'Troef kiezen';

  @override
  String get groningsClearBid => 'Bod wissen';

  @override
  String groningsRaise(int step) {
    return '+$step';
  }

  @override
  String groningsBidOf(String name, int bid) {
    return '$name: $bid';
  }

  @override
  String get groningsChooseBid => 'Kies wie biedt en hoeveel';

  @override
  String get groningsChooseTrump => 'Kies de troef';

  @override
  String groningsBidSummary(String name, int bid) {
    return '$name biedt $bid';
  }

  @override
  String groningsBidMade(int bid) {
    return 'bod $bid gehaald';
  }

  @override
  String groningsBidFailed(int bid) {
    return 'bod $bid niet gehaald';
  }

  @override
  String get suitHearts => 'Harten';

  @override
  String get suitDiamonds => 'Ruiten';

  @override
  String get suitSpades => 'Schoppen';

  @override
  String get suitClubs => 'Klaveren';

  @override
  String get resumeGame => 'Hervat spel';

  @override
  String resumeSubtitle(String game, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondes',
      one: '1 ronde',
      zero: 'nog geen rondes',
    );
    return '$game · $_temp0';
  }

  @override
  String roundsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count rondes',
      one: '1 ronde',
    );
    return '$_temp0';
  }

  @override
  String get playersTitle => 'Spelers';

  @override
  String get addPlayer => 'Speler toevoegen';

  @override
  String get playerName => 'Naam';

  @override
  String get renamePlayer => 'Naam wijzigen';

  @override
  String deletePlayerConfirm(String name) {
    return '$name verwijderen? Eerdere spellen blijven bewaard.';
  }

  @override
  String get nameExists => 'Deze naam bestaat al';

  @override
  String get nameEmpty => 'Vul een naam in';

  @override
  String get noPlayers => 'Nog geen spelers. Voeg ze toe om te beginnen.';

  @override
  String get newGame => 'Nieuw spel';

  @override
  String get choosePlayers => 'Kies spelers';

  @override
  String playersSelected(int count) {
    return '$count geselecteerd';
  }

  @override
  String needPlayers(int min, int max) {
    return 'Kies $min tot $max spelers';
  }

  @override
  String get startGame => 'Start spel';

  @override
  String get newPlayer => 'Nieuwe speler';

  @override
  String get rulesSection => 'Spelregels';

  @override
  String get settingTargetScore => 'Doelscore (0 = geen)';

  @override
  String get settingLowestWins => 'Laagste score wint';

  @override
  String get tabGame => 'Spel';

  @override
  String get tabStanding => 'Stand';

  @override
  String roundTitle(int number) {
    return 'Ronde $number';
  }

  @override
  String enterRound(int number) {
    return 'Ronde $number invoeren';
  }

  @override
  String editRound(int number) {
    return 'Ronde $number corrigeren';
  }

  @override
  String get total => 'Totaal';

  @override
  String get points => 'Punten';

  @override
  String get saveRound => 'Opslaan';

  @override
  String get undoLast => 'Laatste ronde ongedaan maken';

  @override
  String undoConfirm(int number) {
    return 'Ronde $number verwijderen?';
  }

  @override
  String get invalidEntry => 'Vul bij elke speler een geheel getal in';

  @override
  String get finishGame => 'Spel afronden';

  @override
  String get finishConfirm => 'Het spel afronden en bewaren in de historie?';

  @override
  String get gameFinished => 'Spel afgerond';

  @override
  String winnerLabel(String names) {
    return 'Winnaar: $names';
  }

  @override
  String get deleteGame => 'Spel verwijderen';

  @override
  String get deleteGameConfirm =>
      'Dit spel en alle rondes definitief verwijderen?';

  @override
  String get cancel => 'Annuleren';

  @override
  String get confirm => 'Bevestigen';

  @override
  String get delete => 'Verwijderen';

  @override
  String get save => 'Opslaan';

  @override
  String get tapRoundHint => 'Tik op een ronde om te corrigeren';

  @override
  String get noRoundsYet => 'Nog geen rondes';

  @override
  String get progressTitle => 'Verloop';

  @override
  String get historyTitle => 'Historie';

  @override
  String get historyEmpty => 'Nog geen afgeronde spellen';

  @override
  String get statsTitle => 'Statistieken';

  @override
  String get statsPlayed => 'Gespeeld';

  @override
  String get statsWins => 'Gewonnen';

  @override
  String get statsWinPct => 'Winst';

  @override
  String get statsEmpty => 'Nog geen afgeronde spellen';

  @override
  String get settingsTitle => 'Instellingen';

  @override
  String get theme => 'Thema';

  @override
  String get themeSystem => 'Systeem';

  @override
  String get themeLight => 'Licht';

  @override
  String get themeDark => 'Donker';

  @override
  String get haptics => 'Trillen bij invoer';

  @override
  String get resetData => 'Alle gegevens wissen';

  @override
  String get resetConfirm =>
      'Alle spelers, spellen en instellingen definitief wissen?';

  @override
  String get resetDone => 'Alle gegevens zijn gewist';

  @override
  String get copyResult => 'Resultaat kopiëren';

  @override
  String get copied => 'Resultaat gekopieerd';

  @override
  String shareHeader(String game, String date) {
    return '$game – $date';
  }

  @override
  String shareTotalLine(int rank, String name, int score) {
    return '$rank. $name: $score';
  }

  @override
  String get seatOrderHint => 'Volgorde van selecteren is de zitvolgorde';

  @override
  String get gameOver => 'Spel afgelopen';

  @override
  String get gameBoerenbridgeDesc => 'Bieden en slagen, van 1 tot N kaarten';

  @override
  String roundOf(int number, int total) {
    return 'Ronde $number van $total';
  }

  @override
  String cardsCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count kaarten',
      one: '1 kaart',
    );
    return '$_temp0';
  }

  @override
  String dealerLabel(String name) {
    return 'Deler: $name';
  }

  @override
  String get dealerTag => 'deler';

  @override
  String get bidsStep => 'Biedingen';

  @override
  String get tricksStep => 'Slagen';

  @override
  String get bidsSoFar => 'Geboden';

  @override
  String enterBids(int number) {
    return 'Ronde $number: biedingen invoeren';
  }

  @override
  String enterTricks(int number) {
    return 'Ronde $number: slagen invoeren';
  }

  @override
  String get saveBids => 'Biedingen opslaan';

  @override
  String get saveTricks => 'Ronde afronden';

  @override
  String bidsTotal(int bids, int cards) {
    return 'Totaal geboden: $bids van $cards';
  }

  @override
  String tricksTotal(int tricks, int cards) {
    return 'Totaal slagen: $tricks van $cards';
  }

  @override
  String dealerWarning(int bid, int cards) {
    return 'De deler mag niet $bid bieden: het totaal zou gelijk zijn aan het aantal slagen ($cards).';
  }

  @override
  String tricksWarning(int cards) {
    return 'Het totaal aantal slagen moet $cards zijn.';
  }

  @override
  String get issueDealerBid =>
      'De deler mag niet zo bieden dat het totaal gelijk is aan het aantal slagen';

  @override
  String get issueTricksMismatch =>
      'Het totaal aantal slagen moet gelijk zijn aan het aantal kaarten';

  @override
  String get issueOutOfRange => 'Waarde buiten het toegestane bereik';

  @override
  String get settingDealerRestriction => 'Beperking voor de deler';

  @override
  String get settingExactBase => 'Punten bij exact goed (basis)';

  @override
  String get settingExactPerTrick => 'Extra punten per slag bij exact goed';

  @override
  String get settingWrongPerTrick => 'Strafpunten per slag verschil';

  @override
  String get settingMaxCards => 'Max. aantal kaarten (0 = automatisch)';

  @override
  String get next => 'Volgende';

  @override
  String get themeOled => 'OLED-zwart';

  @override
  String get settingStep => 'Stap van de plus- en min-knoppen';

  @override
  String get gameKlaverjassenDesc => 'Wij en Zij, roem, nat en pit';

  @override
  String get teamsHint =>
      'Spelers 1 en 3 vormen Wij, spelers 2 en 4 vormen Zij';

  @override
  String get teamWij => 'Wij';

  @override
  String get teamZij => 'Zij';

  @override
  String get variantAmsterdams => 'Amsterdams';

  @override
  String get variantRotterdams => 'Rotterdams';

  @override
  String get settingVariant => 'Variant';

  @override
  String get settingTieIsNat => 'Gelijke stand is nat';

  @override
  String get settingPitBonus => 'Bonus voor pit';

  @override
  String get settingRoemThree => 'Roem: drie op rij';

  @override
  String get settingRoemFour => 'Roem: vier op rij';

  @override
  String get settingRoemStuk => 'Roem: stuk';

  @override
  String get settingRoemFourEqual => 'Roem: vier gelijke';

  @override
  String get settingRoemFourJacks => 'Roem: vier boeren';

  @override
  String get settingRounds => 'Aantal giffen (0 = onbeperkt)';

  @override
  String get playingTeam => 'Spelende partij';

  @override
  String get pitLabel => 'Pit (alle slagen gehaald)';

  @override
  String cardPointsLine(int playing, int other) {
    return 'Kaartpunten: $playing – $other';
  }

  @override
  String get roemTitle => 'Roem';

  @override
  String get roemHint => 'Tik = erbij, lang indrukken = eraf';

  @override
  String roemTotal(int points) {
    return 'Roem: $points';
  }

  @override
  String get roemThree => 'Drie op rij';

  @override
  String get roemFour => 'Vier op rij';

  @override
  String get roemStuk => 'Stuk';

  @override
  String get roemFourEqual => 'Vier gelijke';

  @override
  String get roemFourJacks => 'Vier boeren';

  @override
  String get natExplain =>
      'Nat: de tegenpartij krijgt alle punten en alle roem';

  @override
  String get pitExplain => 'Pit: alle slagen gehaald, met bonus';

  @override
  String get choosePlaying => 'Kies eerst de spelende partij';

  @override
  String get cardsEmpty => 'Vul de kaartpunten van de spelende partij in';

  @override
  String get gameRikkenDesc => 'Bieden, maat en nul-som uitbetaling';

  @override
  String get rikRik => 'Rik (met maat)';

  @override
  String get rikTroela => 'Troela';

  @override
  String rikAlone(int number) {
    return '$number alleen';
  }

  @override
  String get rikPiek => 'Piek';

  @override
  String get rikMisere => 'Misère';

  @override
  String get rikOpenPiek => 'Open piek';

  @override
  String get rikOpenMisere => 'Open misère';

  @override
  String get rikOpenPiekTalk => 'Open piek met praatje';

  @override
  String get rikOpenMisereTalk => 'Open misère met praatje';

  @override
  String get rikBidder => 'Wie biedt';

  @override
  String get rikContract => 'Contract';

  @override
  String get rikPartner => 'Maat';

  @override
  String get rikTricks => 'Slagen gehaald door de bieder (met maat)';

  @override
  String get rikChooseBidder => 'Kies wie er biedt';

  @override
  String get rikChooseContract => 'Kies het contract';

  @override
  String get rikChoosePartner => 'Kies de maat';

  @override
  String get rikChooseTricks => 'Kies het aantal slagen';

  @override
  String get rikMade => 'Gehaald';

  @override
  String get rikFailed => 'Niet gehaald';

  @override
  String zeroSum(int sum) {
    return 'Som van alle spelers: $sum';
  }

  @override
  String rikBaseLabel(String contract) {
    return '$contract: basispunten';
  }

  @override
  String get settingPerTrick => 'Punten per over- of onderslag';

  @override
  String get settingSlamBonus => 'Bonus voor alle 13 slagen (met maat)';

  @override
  String get settingMaatPays => 'Maat betaalt mee bij verlies';

  @override
  String get gameHartenjagenDesc => 'Strafpunten, schoppen vrouw en de maan';

  @override
  String heartsQueen(int points) {
    return 'Schoppen Vrouw +$points';
  }

  @override
  String get heartsMoon => 'Maan';

  @override
  String get heartsMoonShot => 'De maan is geschoten';

  @override
  String heartsHandedOut(int points, int total) {
    return 'Verdeeld: $points van $total';
  }

  @override
  String get settingTotalPoints => 'Strafpunten per ronde (totaal)';

  @override
  String get settingQueenPoints => 'Strafpunten Schoppen Vrouw';

  @override
  String get settingMoonEnabled => 'Maan schieten toestaan';

  @override
  String get settingMoonMode => 'Bij de maan';

  @override
  String get moonOthers => 'Anderen krijgen het totaal erbij';

  @override
  String get moonShooter => 'Schutter krijgt het totaal eraf';

  @override
  String get gameToepenDesc => 'Punten tikken, op pelt en uitvallen';

  @override
  String get toepenOutBadge => 'uit';

  @override
  String get settingLimit => 'Uitvalgrens (strafpunten)';

  @override
  String get settingPoverty => 'Markeer \'op pelt\' (nog 1 punt tot uit)';

  @override
  String get settingPlayOn => 'Doorspelen tot één speler over is';

  @override
  String get gameJokeren => 'Jokeren';

  @override
  String get gameCanasta => 'Canasta';

  @override
  String get gameJokerenDesc => 'Bedragen optellen per ronde';

  @override
  String get gameCanastaDesc => 'Teams, canasta\'s en doelscore';

  @override
  String get undoLastAmount => 'Laatste bedrag ongedaan maken';

  @override
  String get canastaMeldTitle => 'Minimale eerste meld';

  @override
  String get quickJoker => 'Joker';

  @override
  String get quickAce => 'Aas';

  @override
  String get quickFace => 'Plaatje';

  @override
  String get quickNaturalCanasta => 'Natuurlijke canasta';

  @override
  String get quickMixedCanasta => 'Gemengde canasta';

  @override
  String get quickGoOut => 'Uitgaan';

  @override
  String get quickGoOutConcealed => 'Dicht uitgaan';

  @override
  String get quickRedThree => 'Rode drie';

  @override
  String get quickAllRedThrees => 'Alle rode drieën';

  @override
  String get settingNaturalCanasta => 'Natuurlijke canasta';

  @override
  String get settingMixedCanasta => 'Gemengde canasta';

  @override
  String get settingGoOut => 'Uitgaan';

  @override
  String get settingGoOutConcealed => 'Dicht uitgaan';

  @override
  String get settingRedThree => 'Rode drie';

  @override
  String get settingAllRedThrees => 'Alle vier rode drieën';

  @override
  String get settingQuickJoker => 'Snelknop: joker';

  @override
  String get settingQuickAce => 'Snelknop: aas';

  @override
  String get settingQuickFace => 'Snelknop: plaatje';

  @override
  String get playersTab => 'Spelers';

  @override
  String get groupsTab => 'Groepen';

  @override
  String get addGroup => 'Groep toevoegen';

  @override
  String get editGroup => 'Groep bewerken';

  @override
  String get groupName => 'Groepsnaam';

  @override
  String get groupMembers => 'Leden';

  @override
  String get noGroups =>
      'Nog geen groepen. Maak een vast kaartgroepje om snel te starten.';

  @override
  String deleteGroupConfirm(String name) {
    return '$name verwijderen? Gespeelde spellen blijven bewaard.';
  }

  @override
  String get startFromGroup => 'Start vanuit een groep';

  @override
  String get filterGame => 'Spel';

  @override
  String get filterGroup => 'Groep';

  @override
  String get filterYear => 'Jaar';

  @override
  String get filterAll => 'Alle';

  @override
  String get historyNoMatch => 'Geen spellen met deze filters';

  @override
  String get statsBest => 'Beste score';

  @override
  String kaartkoningTitle(int year) {
    return 'Kaartkoning $year';
  }

  @override
  String kaartkoningWins(int wins, int games) {
    return '$wins winsten in $games spellen';
  }

  @override
  String get shareResult => 'Uitslag delen';

  @override
  String get shareImage => 'Deel als afbeelding';

  @override
  String get shareWatermark => 'Uitslag bijgehouden met de Kaartmaat App';

  @override
  String get padBackspace => 'Wis laatste cijfer';

  @override
  String get padSign => 'Plus of min';

  @override
  String get notAllowed => 'niet toegestaan';

  @override
  String get undoAction => 'Ongedaan maken';

  @override
  String get entered => 'ingevuld';

  @override
  String get editing => 'wordt bewerkt';

  @override
  String roundSaved(int number) {
    return 'Ronde $number opgeslagen';
  }

  @override
  String roundDeleted(int number) {
    return 'Ronde $number verwijderd';
  }

  @override
  String get showProgress => 'Verloop bekijken';

  @override
  String bidShort(int bid) {
    return 'bod $bid';
  }

  @override
  String bidAndWon(int bid, int tricks) {
    return 'bod $bid · $tricks';
  }

  @override
  String get toTricks => 'Naar slagen';

  @override
  String teamPlayed(String team) {
    return '$team speelden';
  }

  @override
  String get pagePoints => 'Punten';

  @override
  String get pageRoem => 'Roem';

  @override
  String cardPointsPair(
    String playTeam,
    int playPoints,
    String otherTeam,
    int otherPoints,
  ) {
    return '$playTeam: $playPoints · $otherTeam: $otherPoints';
  }

  @override
  String get natShort => 'NAT';

  @override
  String get pitShort => 'PIT';

  @override
  String get padClear => 'Alles wissen';

  @override
  String roemInTable(int points) {
    return 'roem $points';
  }

  @override
  String get natInTable => 'nat';

  @override
  String get pitInTable => 'pit';

  @override
  String get rikOvertricks => 'Overslagen';

  @override
  String get rikUndertricks => 'Onderslagen';

  @override
  String get rikFewer => 'Eén minder';

  @override
  String get rikMore => 'Eén meer';

  @override
  String rikExactNote(int target) {
    return 'Precies $target slagen nodig';
  }

  @override
  String rikPartnerCrumb(String name) {
    return 'maat $name';
  }

  @override
  String get rikResultCrumb => 'Uitslag';

  @override
  String get rikPartnerShort => 'maat';

  @override
  String get rikShortRik => 'Rik';

  @override
  String get rikShortOpenPiekTalk => 'Open piek + praat';

  @override
  String get rikShortOpenMisereTalk => 'Open misère + praat';

  @override
  String get heartsQueenShort => 'SV';

  @override
  String get heartsTooMany => 'Er zijn niet zoveel harten';

  @override
  String get heartsQueenMissing => 'Wie heeft de Schoppen Vrouw?';

  @override
  String get toepenPovertyBadge => 'op pelt';

  @override
  String get calcDone => 'Klaar';

  @override
  String get calcAdd => 'Bedrag optellen';

  @override
  String get calcTapeEmpty => 'Nog geen bedragen';

  @override
  String get saveRoundShort => 'Ronde opslaan';

  @override
  String get pageDigits => 'Cijfers';

  @override
  String get pageQuick => 'Snel';

  @override
  String get nextRound => 'Volgende ronde';

  @override
  String get counterCustom => 'Eigen';

  @override
  String get counterCustomStep => 'Eigen stap';

  @override
  String counterStepSemantics(int number) {
    return 'Stap $number';
  }

  @override
  String counterPlus(int number) {
    return 'Plus $number';
  }

  @override
  String counterMinus(int number) {
    return 'Min $number';
  }

  @override
  String counterThisRound(String value) {
    return 'deze ronde $value';
  }
}
