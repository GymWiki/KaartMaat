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
  String get gameCustomDesc =>
      'Pesten, Ezelen en meer: plus en min met eigen stap';

  @override
  String get gameBoerenbridge => 'Boerenbridge';

  @override
  String get gameKlaverjassen => 'Klaverjassen';

  @override
  String get gameYatzy => 'Yatzy';

  @override
  String get gameToepen => 'Toepen';

  @override
  String get gameRikken => 'Rikken';

  @override
  String get gameHartenjagen => 'Hartenjagen';

  @override
  String get comingSoon => 'Binnenkort';

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
  String get gameToepenDesc => 'Kloppen, armoede en uitvallen';

  @override
  String get toepenWinner => 'Winnaar van de ronde';

  @override
  String get toepenKnocks => 'Aantal keer geklopt';

  @override
  String get toepenStay => 'Gaat mee';

  @override
  String toepenFoldAt(int number) {
    return 'Past bij klop $number';
  }

  @override
  String get toepenPovertyKnock => 'De armoede-klop telt mee als klop 1';

  @override
  String toepenInPoverty(String names) {
    return 'In de armoe: $names';
  }

  @override
  String toepenOut(String names) {
    return 'Uit: $names';
  }

  @override
  String get toepenOutBadge => 'uit';

  @override
  String get toepenChooseWinner => 'Kies de winnaar van de ronde';

  @override
  String get settingLimit => 'Uitvalgrens (strafpunten)';

  @override
  String get settingPoverty => 'Armoede telt als klop';

  @override
  String get settingPlayOn => 'Doorspelen tot één speler over is';
}
