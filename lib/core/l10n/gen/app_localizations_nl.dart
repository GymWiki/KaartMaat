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
  String get gameCustom => 'Eigen spel';

  @override
  String get gameCustomDesc => 'Eigen puntentelling, optioneel met doelscore';

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
  String get targetReached => 'Doelscore bereikt';

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
  String historyLimited(int count) {
    return 'Gratis: laatste $count spellen. Ontgrendel voor de volledige historie.';
  }

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
  String get statsLocked => 'Statistieken zitten in Alles ontgrendelen.';

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
  String get debugUnlock => 'Debug: alles ontgrendeld';

  @override
  String get unlockTitle => 'Alles ontgrendelen';

  @override
  String unlockBody(String price) {
    return 'Eenmalig $price: alle spellen, volledige historie, statistieken en delen.';
  }

  @override
  String unlockBuy(String price) {
    return 'Ontgrendelen voor $price';
  }

  @override
  String get restorePurchases => 'Aankopen herstellen';

  @override
  String get restoreNone => 'Geen eerdere aankoop gevonden';

  @override
  String get unlockedDone => 'Alles is ontgrendeld';

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
  String get lockedGame => 'Vergrendeld';

  @override
  String get seatOrderHint => 'Volgorde van selecteren is de zitvolgorde';
}
