import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_nl.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('nl')];

  /// No description provided for @appTitle.
  ///
  /// In nl, this message translates to:
  /// **'Kaartmaat'**
  String get appTitle;

  /// No description provided for @navGames.
  ///
  /// In nl, this message translates to:
  /// **'Spellen'**
  String get navGames;

  /// No description provided for @navPlayers.
  ///
  /// In nl, this message translates to:
  /// **'Spelers'**
  String get navPlayers;

  /// No description provided for @navHistory.
  ///
  /// In nl, this message translates to:
  /// **'Historie'**
  String get navHistory;

  /// No description provided for @navStats.
  ///
  /// In nl, this message translates to:
  /// **'Statistieken'**
  String get navStats;

  /// No description provided for @navSettings.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get navSettings;

  /// No description provided for @gameCustom.
  ///
  /// In nl, this message translates to:
  /// **'Eigen spel'**
  String get gameCustom;

  /// No description provided for @gameCustomDesc.
  ///
  /// In nl, this message translates to:
  /// **'Eigen puntentelling, optioneel met doelscore'**
  String get gameCustomDesc;

  /// No description provided for @gameBoerenbridge.
  ///
  /// In nl, this message translates to:
  /// **'Boerenbridge'**
  String get gameBoerenbridge;

  /// No description provided for @gameKlaverjassen.
  ///
  /// In nl, this message translates to:
  /// **'Klaverjassen'**
  String get gameKlaverjassen;

  /// No description provided for @gameYatzy.
  ///
  /// In nl, this message translates to:
  /// **'Yatzy'**
  String get gameYatzy;

  /// No description provided for @gameToepen.
  ///
  /// In nl, this message translates to:
  /// **'Toepen'**
  String get gameToepen;

  /// No description provided for @gameRikken.
  ///
  /// In nl, this message translates to:
  /// **'Rikken'**
  String get gameRikken;

  /// No description provided for @gameHartenjagen.
  ///
  /// In nl, this message translates to:
  /// **'Hartenjagen'**
  String get gameHartenjagen;

  /// No description provided for @comingSoon.
  ///
  /// In nl, this message translates to:
  /// **'Binnenkort'**
  String get comingSoon;

  /// No description provided for @resumeGame.
  ///
  /// In nl, this message translates to:
  /// **'Hervat spel'**
  String get resumeGame;

  /// No description provided for @resumeSubtitle.
  ///
  /// In nl, this message translates to:
  /// **'{game} · {count, plural, =0{nog geen rondes} =1{1 ronde} other{{count} rondes}}'**
  String resumeSubtitle(String game, int count);

  /// No description provided for @roundsCount.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 ronde} other{{count} rondes}}'**
  String roundsCount(int count);

  /// No description provided for @playersTitle.
  ///
  /// In nl, this message translates to:
  /// **'Spelers'**
  String get playersTitle;

  /// No description provided for @addPlayer.
  ///
  /// In nl, this message translates to:
  /// **'Speler toevoegen'**
  String get addPlayer;

  /// No description provided for @playerName.
  ///
  /// In nl, this message translates to:
  /// **'Naam'**
  String get playerName;

  /// No description provided for @renamePlayer.
  ///
  /// In nl, this message translates to:
  /// **'Naam wijzigen'**
  String get renamePlayer;

  /// No description provided for @deletePlayerConfirm.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen? Eerdere spellen blijven bewaard.'**
  String deletePlayerConfirm(String name);

  /// No description provided for @nameExists.
  ///
  /// In nl, this message translates to:
  /// **'Deze naam bestaat al'**
  String get nameExists;

  /// No description provided for @nameEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Vul een naam in'**
  String get nameEmpty;

  /// No description provided for @noPlayers.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen spelers. Voeg ze toe om te beginnen.'**
  String get noPlayers;

  /// No description provided for @newGame.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw spel'**
  String get newGame;

  /// No description provided for @choosePlayers.
  ///
  /// In nl, this message translates to:
  /// **'Kies spelers'**
  String get choosePlayers;

  /// No description provided for @playersSelected.
  ///
  /// In nl, this message translates to:
  /// **'{count} geselecteerd'**
  String playersSelected(int count);

  /// No description provided for @needPlayers.
  ///
  /// In nl, this message translates to:
  /// **'Kies {min} tot {max} spelers'**
  String needPlayers(int min, int max);

  /// No description provided for @startGame.
  ///
  /// In nl, this message translates to:
  /// **'Start spel'**
  String get startGame;

  /// No description provided for @newPlayer.
  ///
  /// In nl, this message translates to:
  /// **'Nieuwe speler'**
  String get newPlayer;

  /// No description provided for @rulesSection.
  ///
  /// In nl, this message translates to:
  /// **'Spelregels'**
  String get rulesSection;

  /// No description provided for @settingTargetScore.
  ///
  /// In nl, this message translates to:
  /// **'Doelscore (0 = geen)'**
  String get settingTargetScore;

  /// No description provided for @settingLowestWins.
  ///
  /// In nl, this message translates to:
  /// **'Laagste score wint'**
  String get settingLowestWins;

  /// No description provided for @tabGame.
  ///
  /// In nl, this message translates to:
  /// **'Spel'**
  String get tabGame;

  /// No description provided for @tabStanding.
  ///
  /// In nl, this message translates to:
  /// **'Stand'**
  String get tabStanding;

  /// No description provided for @roundTitle.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number}'**
  String roundTitle(int number);

  /// No description provided for @enterRound.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} invoeren'**
  String enterRound(int number);

  /// No description provided for @editRound.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} corrigeren'**
  String editRound(int number);

  /// No description provided for @total.
  ///
  /// In nl, this message translates to:
  /// **'Totaal'**
  String get total;

  /// No description provided for @points.
  ///
  /// In nl, this message translates to:
  /// **'Punten'**
  String get points;

  /// No description provided for @saveRound.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get saveRound;

  /// No description provided for @undoLast.
  ///
  /// In nl, this message translates to:
  /// **'Laatste ronde ongedaan maken'**
  String get undoLast;

  /// No description provided for @undoConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} verwijderen?'**
  String undoConfirm(int number);

  /// No description provided for @invalidEntry.
  ///
  /// In nl, this message translates to:
  /// **'Vul bij elke speler een geheel getal in'**
  String get invalidEntry;

  /// No description provided for @finishGame.
  ///
  /// In nl, this message translates to:
  /// **'Spel afronden'**
  String get finishGame;

  /// No description provided for @finishConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Het spel afronden en bewaren in de historie?'**
  String get finishConfirm;

  /// No description provided for @gameFinished.
  ///
  /// In nl, this message translates to:
  /// **'Spel afgerond'**
  String get gameFinished;

  /// No description provided for @winnerLabel.
  ///
  /// In nl, this message translates to:
  /// **'Winnaar: {names}'**
  String winnerLabel(String names);

  /// No description provided for @deleteGame.
  ///
  /// In nl, this message translates to:
  /// **'Spel verwijderen'**
  String get deleteGame;

  /// No description provided for @deleteGameConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Dit spel en alle rondes definitief verwijderen?'**
  String get deleteGameConfirm;

  /// No description provided for @cancel.
  ///
  /// In nl, this message translates to:
  /// **'Annuleren'**
  String get cancel;

  /// No description provided for @confirm.
  ///
  /// In nl, this message translates to:
  /// **'Bevestigen'**
  String get confirm;

  /// No description provided for @delete.
  ///
  /// In nl, this message translates to:
  /// **'Verwijderen'**
  String get delete;

  /// No description provided for @save.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan'**
  String get save;

  /// No description provided for @tapRoundHint.
  ///
  /// In nl, this message translates to:
  /// **'Tik op een ronde om te corrigeren'**
  String get tapRoundHint;

  /// No description provided for @noRoundsYet.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen rondes'**
  String get noRoundsYet;

  /// No description provided for @progressTitle.
  ///
  /// In nl, this message translates to:
  /// **'Verloop'**
  String get progressTitle;

  /// No description provided for @historyTitle.
  ///
  /// In nl, this message translates to:
  /// **'Historie'**
  String get historyTitle;

  /// No description provided for @historyEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen afgeronde spellen'**
  String get historyEmpty;

  /// No description provided for @statsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Statistieken'**
  String get statsTitle;

  /// No description provided for @statsPlayed.
  ///
  /// In nl, this message translates to:
  /// **'Gespeeld'**
  String get statsPlayed;

  /// No description provided for @statsWins.
  ///
  /// In nl, this message translates to:
  /// **'Gewonnen'**
  String get statsWins;

  /// No description provided for @statsWinPct.
  ///
  /// In nl, this message translates to:
  /// **'Winst'**
  String get statsWinPct;

  /// No description provided for @statsEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen afgeronde spellen'**
  String get statsEmpty;

  /// No description provided for @settingsTitle.
  ///
  /// In nl, this message translates to:
  /// **'Instellingen'**
  String get settingsTitle;

  /// No description provided for @theme.
  ///
  /// In nl, this message translates to:
  /// **'Thema'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In nl, this message translates to:
  /// **'Systeem'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In nl, this message translates to:
  /// **'Licht'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In nl, this message translates to:
  /// **'Donker'**
  String get themeDark;

  /// No description provided for @haptics.
  ///
  /// In nl, this message translates to:
  /// **'Trillen bij invoer'**
  String get haptics;

  /// No description provided for @resetData.
  ///
  /// In nl, this message translates to:
  /// **'Alle gegevens wissen'**
  String get resetData;

  /// No description provided for @resetConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Alle spelers, spellen en instellingen definitief wissen?'**
  String get resetConfirm;

  /// No description provided for @resetDone.
  ///
  /// In nl, this message translates to:
  /// **'Alle gegevens zijn gewist'**
  String get resetDone;

  /// No description provided for @copyResult.
  ///
  /// In nl, this message translates to:
  /// **'Resultaat kopiëren'**
  String get copyResult;

  /// No description provided for @copied.
  ///
  /// In nl, this message translates to:
  /// **'Resultaat gekopieerd'**
  String get copied;

  /// No description provided for @shareHeader.
  ///
  /// In nl, this message translates to:
  /// **'{game} – {date}'**
  String shareHeader(String game, String date);

  /// No description provided for @shareTotalLine.
  ///
  /// In nl, this message translates to:
  /// **'{rank}. {name}: {score}'**
  String shareTotalLine(int rank, String name, int score);

  /// No description provided for @seatOrderHint.
  ///
  /// In nl, this message translates to:
  /// **'Volgorde van selecteren is de zitvolgorde'**
  String get seatOrderHint;

  /// No description provided for @gameOver.
  ///
  /// In nl, this message translates to:
  /// **'Spel afgelopen'**
  String get gameOver;

  /// No description provided for @gameBoerenbridgeDesc.
  ///
  /// In nl, this message translates to:
  /// **'Bieden en slagen, van 1 tot N kaarten'**
  String get gameBoerenbridgeDesc;

  /// No description provided for @roundOf.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} van {total}'**
  String roundOf(int number, int total);

  /// No description provided for @cardsCount.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 kaart} other{{count} kaarten}}'**
  String cardsCount(int count);

  /// No description provided for @dealerLabel.
  ///
  /// In nl, this message translates to:
  /// **'Deler: {name}'**
  String dealerLabel(String name);

  /// No description provided for @dealerTag.
  ///
  /// In nl, this message translates to:
  /// **'deler'**
  String get dealerTag;

  /// No description provided for @bidsStep.
  ///
  /// In nl, this message translates to:
  /// **'Biedingen'**
  String get bidsStep;

  /// No description provided for @tricksStep.
  ///
  /// In nl, this message translates to:
  /// **'Slagen'**
  String get tricksStep;

  /// No description provided for @bidsSoFar.
  ///
  /// In nl, this message translates to:
  /// **'Geboden'**
  String get bidsSoFar;

  /// No description provided for @enterBids.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number}: biedingen invoeren'**
  String enterBids(int number);

  /// No description provided for @enterTricks.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number}: slagen invoeren'**
  String enterTricks(int number);

  /// No description provided for @saveBids.
  ///
  /// In nl, this message translates to:
  /// **'Biedingen opslaan'**
  String get saveBids;

  /// No description provided for @saveTricks.
  ///
  /// In nl, this message translates to:
  /// **'Ronde afronden'**
  String get saveTricks;

  /// No description provided for @bidsTotal.
  ///
  /// In nl, this message translates to:
  /// **'Totaal geboden: {bids} van {cards}'**
  String bidsTotal(int bids, int cards);

  /// No description provided for @tricksTotal.
  ///
  /// In nl, this message translates to:
  /// **'Totaal slagen: {tricks} van {cards}'**
  String tricksTotal(int tricks, int cards);

  /// No description provided for @dealerWarning.
  ///
  /// In nl, this message translates to:
  /// **'De deler mag niet {bid} bieden: het totaal zou gelijk zijn aan het aantal slagen ({cards}).'**
  String dealerWarning(int bid, int cards);

  /// No description provided for @tricksWarning.
  ///
  /// In nl, this message translates to:
  /// **'Het totaal aantal slagen moet {cards} zijn.'**
  String tricksWarning(int cards);

  /// No description provided for @issueDealerBid.
  ///
  /// In nl, this message translates to:
  /// **'De deler mag niet zo bieden dat het totaal gelijk is aan het aantal slagen'**
  String get issueDealerBid;

  /// No description provided for @issueTricksMismatch.
  ///
  /// In nl, this message translates to:
  /// **'Het totaal aantal slagen moet gelijk zijn aan het aantal kaarten'**
  String get issueTricksMismatch;

  /// No description provided for @issueOutOfRange.
  ///
  /// In nl, this message translates to:
  /// **'Waarde buiten het toegestane bereik'**
  String get issueOutOfRange;

  /// No description provided for @settingDealerRestriction.
  ///
  /// In nl, this message translates to:
  /// **'Beperking voor de deler'**
  String get settingDealerRestriction;

  /// No description provided for @settingExactBase.
  ///
  /// In nl, this message translates to:
  /// **'Punten bij exact goed (basis)'**
  String get settingExactBase;

  /// No description provided for @settingExactPerTrick.
  ///
  /// In nl, this message translates to:
  /// **'Extra punten per slag bij exact goed'**
  String get settingExactPerTrick;

  /// No description provided for @settingWrongPerTrick.
  ///
  /// In nl, this message translates to:
  /// **'Strafpunten per slag verschil'**
  String get settingWrongPerTrick;

  /// No description provided for @settingMaxCards.
  ///
  /// In nl, this message translates to:
  /// **'Max. aantal kaarten (0 = automatisch)'**
  String get settingMaxCards;

  /// No description provided for @next.
  ///
  /// In nl, this message translates to:
  /// **'Volgende'**
  String get next;

  /// No description provided for @themeOled.
  ///
  /// In nl, this message translates to:
  /// **'OLED-zwart'**
  String get themeOled;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['nl'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'nl':
      return AppLocalizationsNl();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
