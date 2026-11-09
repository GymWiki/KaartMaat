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
  /// **'Algemene teller'**
  String get gameCustom;

  /// No description provided for @gameCustomDesc.
  ///
  /// In nl, this message translates to:
  /// **'Pesten, Ezelen en andere spellen'**
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

  /// No description provided for @otherRunningGames.
  ///
  /// In nl, this message translates to:
  /// **'Andere lopende spellen'**
  String get otherRunningGames;

  /// No description provided for @settingEndMode.
  ///
  /// In nl, this message translates to:
  /// **'Het spel eindigt'**
  String get settingEndMode;

  /// No description provided for @endModeHands.
  ///
  /// In nl, this message translates to:
  /// **'Na een aantal giffen'**
  String get endModeHands;

  /// No description provided for @endModeTarget.
  ///
  /// In nl, this message translates to:
  /// **'Bij een streefscore'**
  String get endModeTarget;

  /// No description provided for @settingTargetInclusive.
  ///
  /// In nl, this message translates to:
  /// **'Streefscore zelf telt mee (5000 of meer)'**
  String get settingTargetInclusive;

  /// No description provided for @sharedWin.
  ///
  /// In nl, this message translates to:
  /// **'Gedeelde winst'**
  String get sharedWin;

  /// No description provided for @roundsPlayed.
  ///
  /// In nl, this message translates to:
  /// **'{count, plural, =1{1 ronde gespeeld} other{{count} rondes gespeeld}}'**
  String roundsPlayed(int count);

  /// No description provided for @shareCaption.
  ///
  /// In nl, this message translates to:
  /// **'Uitslag {game}: {winner} wint met {points} punten'**
  String shareCaption(String game, String winner, int points);

  /// No description provided for @shareCaptionTie.
  ///
  /// In nl, this message translates to:
  /// **'Uitslag {game}: gedeelde winst voor {winner} met {points} punten'**
  String shareCaptionTie(String game, String winner, int points);

  /// No description provided for @shareAction.
  ///
  /// In nl, this message translates to:
  /// **'Delen'**
  String get shareAction;

  /// No description provided for @saveImage.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan als afbeelding'**
  String get saveImage;

  /// No description provided for @imageSaved.
  ///
  /// In nl, this message translates to:
  /// **'Afbeelding opgeslagen in de galerij'**
  String get imageSaved;

  /// No description provided for @imageSaveDenied.
  ///
  /// In nl, this message translates to:
  /// **'Geen toegang om de afbeelding op te slaan'**
  String get imageSaveDenied;

  /// No description provided for @imageSaveFailed.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan is niet gelukt'**
  String get imageSaveFailed;

  /// No description provided for @shareFailed.
  ///
  /// In nl, this message translates to:
  /// **'Delen is niet gelukt'**
  String get shareFailed;

  /// No description provided for @newGameAgain.
  ///
  /// In nl, this message translates to:
  /// **'Nieuw spel'**
  String get newGameAgain;

  /// No description provided for @resumeFinished.
  ///
  /// In nl, this message translates to:
  /// **'Hervat spel'**
  String get resumeFinished;

  /// No description provided for @resumeFinishedConfirm.
  ///
  /// In nl, this message translates to:
  /// **'Het spel weer openen om verder te spelen of te corrigeren?'**
  String get resumeFinishedConfirm;

  /// No description provided for @closeResult.
  ///
  /// In nl, this message translates to:
  /// **'Sluiten'**
  String get closeResult;

  /// No description provided for @gameDuizenden.
  ///
  /// In nl, this message translates to:
  /// **'Duizenden'**
  String get gameDuizenden;

  /// No description provided for @gameDuizendenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Als eerste naar 1000 punten'**
  String get gameDuizendenDesc;

  /// No description provided for @duizendenHint.
  ///
  /// In nl, this message translates to:
  /// **'Wie als eerste de doelscore haalt (standaard 1000) wint. Een score per ronde mag negatief zijn. Het spel eindigt aan het einde van een ronde: halen meer spelers de doelscore, dan wint de hoogste stand.'**
  String get duizendenHint;

  /// No description provided for @duizendenToGo.
  ///
  /// In nl, this message translates to:
  /// **'nog {points}'**
  String duizendenToGo(int points);

  /// No description provided for @duizendenReached.
  ///
  /// In nl, this message translates to:
  /// **'doel bereikt'**
  String get duizendenReached;

  /// No description provided for @scoreOutOfRange.
  ///
  /// In nl, this message translates to:
  /// **'Score buiten {min} tot {max}'**
  String scoreOutOfRange(int min, int max);

  /// No description provided for @duizendenReaches.
  ///
  /// In nl, this message translates to:
  /// **'{names} haalt de doelscore'**
  String duizendenReaches(String names);

  /// No description provided for @scoreFillAll.
  ///
  /// In nl, this message translates to:
  /// **'Vul de score van alle spelers in'**
  String get scoreFillAll;

  /// No description provided for @variantGronings.
  ///
  /// In nl, this message translates to:
  /// **'Gronings'**
  String get variantGronings;

  /// No description provided for @variantHintAmsterdams.
  ///
  /// In nl, this message translates to:
  /// **'Gewoon klaverjassen: de spelende partij moet meer punten halen dan de tegenpartij.'**
  String get variantHintAmsterdams;

  /// No description provided for @variantHintRotterdams.
  ///
  /// In nl, this message translates to:
  /// **'Rekent in de app hetzelfde als Amsterdams.'**
  String get variantHintRotterdams;

  /// No description provided for @variantHintGronings.
  ///
  /// In nl, this message translates to:
  /// **'Eerst bieden: de spelende partij moet haar bod halen (met roem). Troeven is verplicht; overtroeven niet als de slag al van je maat is.'**
  String get variantHintGronings;

  /// No description provided for @settingMinBid.
  ///
  /// In nl, this message translates to:
  /// **'Laagste bod'**
  String get settingMinBid;

  /// No description provided for @settingMaxBid.
  ///
  /// In nl, this message translates to:
  /// **'Hoogste bod'**
  String get settingMaxBid;

  /// No description provided for @groningsBidTitle.
  ///
  /// In nl, this message translates to:
  /// **'Bieden'**
  String get groningsBidTitle;

  /// No description provided for @groningsPass.
  ///
  /// In nl, this message translates to:
  /// **'Iedereen past'**
  String get groningsPass;

  /// No description provided for @groningsForced.
  ///
  /// In nl, this message translates to:
  /// **'{name} moet {bid} bieden'**
  String groningsForced(String name, int bid);

  /// No description provided for @groningsToTrump.
  ///
  /// In nl, this message translates to:
  /// **'Troef kiezen'**
  String get groningsToTrump;

  /// No description provided for @groningsClearBid.
  ///
  /// In nl, this message translates to:
  /// **'Bod wissen'**
  String get groningsClearBid;

  /// No description provided for @groningsRaise.
  ///
  /// In nl, this message translates to:
  /// **'+{step}'**
  String groningsRaise(int step);

  /// No description provided for @groningsBidOf.
  ///
  /// In nl, this message translates to:
  /// **'{name}: {bid}'**
  String groningsBidOf(String name, int bid);

  /// No description provided for @groningsChooseBid.
  ///
  /// In nl, this message translates to:
  /// **'Kies wie biedt en hoeveel'**
  String get groningsChooseBid;

  /// No description provided for @groningsChooseTrump.
  ///
  /// In nl, this message translates to:
  /// **'Kies de troef'**
  String get groningsChooseTrump;

  /// No description provided for @groningsBidSummary.
  ///
  /// In nl, this message translates to:
  /// **'{name} biedt {bid}'**
  String groningsBidSummary(String name, int bid);

  /// No description provided for @groningsBidMade.
  ///
  /// In nl, this message translates to:
  /// **'bod {bid} gehaald'**
  String groningsBidMade(int bid);

  /// No description provided for @groningsBidFailed.
  ///
  /// In nl, this message translates to:
  /// **'bod {bid} niet gehaald'**
  String groningsBidFailed(int bid);

  /// No description provided for @suitHearts.
  ///
  /// In nl, this message translates to:
  /// **'Harten'**
  String get suitHearts;

  /// No description provided for @suitDiamonds.
  ///
  /// In nl, this message translates to:
  /// **'Ruiten'**
  String get suitDiamonds;

  /// No description provided for @suitSpades.
  ///
  /// In nl, this message translates to:
  /// **'Schoppen'**
  String get suitSpades;

  /// No description provided for @suitClubs.
  ///
  /// In nl, this message translates to:
  /// **'Klaveren'**
  String get suitClubs;

  /// No description provided for @keepAwakeOn.
  ///
  /// In nl, this message translates to:
  /// **'Scherm blijft aan'**
  String get keepAwakeOn;

  /// No description provided for @keepAwakeOff.
  ///
  /// In nl, this message translates to:
  /// **'Scherm mag uit'**
  String get keepAwakeOff;

  /// No description provided for @keepAwakeTooltip.
  ///
  /// In nl, this message translates to:
  /// **'Scherm aan houden'**
  String get keepAwakeTooltip;

  /// No description provided for @settingKeepAwake.
  ///
  /// In nl, this message translates to:
  /// **'Scherm standaard aan tijdens spel'**
  String get settingKeepAwake;

  /// No description provided for @settingInputMode.
  ///
  /// In nl, this message translates to:
  /// **'Invoermethode'**
  String get settingInputMode;

  /// No description provided for @inputModeAdd.
  ///
  /// In nl, this message translates to:
  /// **'Optellen'**
  String get inputModeAdd;

  /// No description provided for @inputModeEnter.
  ///
  /// In nl, this message translates to:
  /// **'Invullen'**
  String get inputModeEnter;

  /// No description provided for @inputModeHintAdd.
  ///
  /// In nl, this message translates to:
  /// **'Tik op knoppen om punten bij spelers op te tellen.'**
  String get inputModeHintAdd;

  /// No description provided for @inputModeHintEnter.
  ///
  /// In nl, this message translates to:
  /// **'Vul per ronde de score van elke speler in met het numpad.'**
  String get inputModeHintEnter;

  /// No description provided for @dealerSemantics.
  ///
  /// In nl, this message translates to:
  /// **'Deler'**
  String get dealerSemantics;

  /// No description provided for @firstBidderSemantics.
  ///
  /// In nl, this message translates to:
  /// **'Eerste bieder'**
  String get firstBidderSemantics;

  /// No description provided for @atTableTitle.
  ///
  /// In nl, this message translates to:
  /// **'Aan tafel ({count})'**
  String atTableTitle(int count);

  /// No description provided for @atTableHint.
  ///
  /// In nl, this message translates to:
  /// **'Tik hieronder op spelers om ze aan tafel te zetten. Sleep om de zitvolgorde te wijzigen.'**
  String get atTableHint;

  /// No description provided for @removeFromTable.
  ///
  /// In nl, this message translates to:
  /// **'Van tafel halen'**
  String get removeFromTable;

  /// No description provided for @moveSeat.
  ///
  /// In nl, this message translates to:
  /// **'Verplaats {name}'**
  String moveSeat(String name);

  /// No description provided for @showAllPlayers.
  ///
  /// In nl, this message translates to:
  /// **'Toon alle ({count})'**
  String showAllPlayers(int count);

  /// No description provided for @showFewerPlayers.
  ///
  /// In nl, this message translates to:
  /// **'Toon minder'**
  String get showFewerPlayers;

  /// No description provided for @searchPlayer.
  ///
  /// In nl, this message translates to:
  /// **'Zoek speler'**
  String get searchPlayer;

  /// No description provided for @noPlayerMatch.
  ///
  /// In nl, this message translates to:
  /// **'Geen speler gevonden'**
  String get noPlayerMatch;

  /// No description provided for @saveAsGroup.
  ///
  /// In nl, this message translates to:
  /// **'Opslaan als groep'**
  String get saveAsGroup;

  /// No description provided for @groupSavedMsg.
  ///
  /// In nl, this message translates to:
  /// **'Groep {name} opgeslagen'**
  String groupSavedMsg(String name);

  /// No description provided for @groupSelectedMsg.
  ///
  /// In nl, this message translates to:
  /// **'{name} geselecteerd'**
  String groupSelectedMsg(String name);

  /// No description provided for @groupTruncatedMsg.
  ///
  /// In nl, this message translates to:
  /// **'{game} is max. {max} spelers: de eerste {max} van {name} zijn gekozen'**
  String groupTruncatedMsg(String game, int max, String name);

  /// No description provided for @maxPlayersMsg.
  ///
  /// In nl, this message translates to:
  /// **'{game} is max. {max} spelers'**
  String maxPlayersMsg(String game, int max);

  /// No description provided for @groupChipLabel.
  ///
  /// In nl, this message translates to:
  /// **'{name} ({count})'**
  String groupChipLabel(String name, int count);

  /// No description provided for @groupChipAdd.
  ///
  /// In nl, this message translates to:
  /// **'Groep'**
  String get groupChipAdd;

  /// No description provided for @proTitle.
  ///
  /// In nl, this message translates to:
  /// **'Kaartmaat Pro'**
  String get proTitle;

  /// No description provided for @proIntro.
  ///
  /// In nl, this message translates to:
  /// **'Alle spellen blijven gratis. Met Pro krijg je er dit bij:'**
  String get proIntro;

  /// No description provided for @proFeatureStats.
  ///
  /// In nl, this message translates to:
  /// **'Statistieken en de Kaartkoning van het jaar'**
  String get proFeatureStats;

  /// No description provided for @proFeatureHistory.
  ///
  /// In nl, this message translates to:
  /// **'Historie van al je afgeronde spellen'**
  String get proFeatureHistory;

  /// No description provided for @proFeatureGroups.
  ///
  /// In nl, this message translates to:
  /// **'Spelersgroepen om snel te selecteren'**
  String get proFeatureGroups;

  /// No description provided for @proOnce.
  ///
  /// In nl, this message translates to:
  /// **'Eenmalig, geen abonnement'**
  String get proOnce;

  /// No description provided for @proUnlock.
  ///
  /// In nl, this message translates to:
  /// **'Ontgrendel Pro'**
  String get proUnlock;

  /// No description provided for @proRestore.
  ///
  /// In nl, this message translates to:
  /// **'Aankopen herstellen'**
  String get proRestore;

  /// No description provided for @proRestoring.
  ///
  /// In nl, this message translates to:
  /// **'Aankopen worden hersteld…'**
  String get proRestoring;

  /// No description provided for @proThanks.
  ///
  /// In nl, this message translates to:
  /// **'Bedankt! Pro is ontgrendeld'**
  String get proThanks;

  /// No description provided for @proPending.
  ///
  /// In nl, this message translates to:
  /// **'Betaling in behandeling. Pro wordt ontgrendeld zodra de betaling is bevestigd.'**
  String get proPending;

  /// No description provided for @proFailed.
  ///
  /// In nl, this message translates to:
  /// **'De aankoop is niet gelukt. Er is niets afgeschreven. Probeer het later opnieuw.'**
  String get proFailed;

  /// No description provided for @proRestoreNone.
  ///
  /// In nl, this message translates to:
  /// **'Er is geen eerdere aankoop gevonden bij dit account.'**
  String get proRestoreNone;

  /// No description provided for @proProductError.
  ///
  /// In nl, this message translates to:
  /// **'De prijs kon niet worden opgehaald. Controleer je verbinding en probeer het opnieuw.'**
  String get proProductError;

  /// No description provided for @proLoadingPrice.
  ///
  /// In nl, this message translates to:
  /// **'Prijs wordt geladen…'**
  String get proLoadingPrice;

  /// No description provided for @proRetry.
  ///
  /// In nl, this message translates to:
  /// **'Opnieuw proberen'**
  String get proRetry;

  /// No description provided for @proDebugOverride.
  ///
  /// In nl, this message translates to:
  /// **'Pro forceren (alleen debug)'**
  String get proDebugOverride;

  /// No description provided for @proDebugAuto.
  ///
  /// In nl, this message translates to:
  /// **'Automatisch'**
  String get proDebugAuto;

  /// No description provided for @proDebugOn.
  ///
  /// In nl, this message translates to:
  /// **'Pro aan'**
  String get proDebugOn;

  /// No description provided for @proDebugOff.
  ///
  /// In nl, this message translates to:
  /// **'Pro uit'**
  String get proDebugOff;

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
  /// **'Bieden mag niet kloppen'**
  String get settingDealerRestriction;

  /// No description provided for @settingDealerRestrictionHint.
  ///
  /// In nl, this message translates to:
  /// **'Het totaal van alle biedingen mag niet gelijk zijn aan het aantal slagen. Zo is er altijd een verliezer.'**
  String get settingDealerRestrictionHint;

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

  /// No description provided for @settingStep.
  ///
  /// In nl, this message translates to:
  /// **'Stap van de plus- en min-knoppen'**
  String get settingStep;

  /// No description provided for @gameKlaverjassenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Wij en Zij, roem, nat en pit'**
  String get gameKlaverjassenDesc;

  /// No description provided for @teamsHint.
  ///
  /// In nl, this message translates to:
  /// **'Spelers 1 en 3 vormen Wij, spelers 2 en 4 vormen Zij'**
  String get teamsHint;

  /// No description provided for @teamWij.
  ///
  /// In nl, this message translates to:
  /// **'Wij'**
  String get teamWij;

  /// No description provided for @teamZij.
  ///
  /// In nl, this message translates to:
  /// **'Zij'**
  String get teamZij;

  /// No description provided for @variantAmsterdams.
  ///
  /// In nl, this message translates to:
  /// **'Amsterdams'**
  String get variantAmsterdams;

  /// No description provided for @variantRotterdams.
  ///
  /// In nl, this message translates to:
  /// **'Rotterdams'**
  String get variantRotterdams;

  /// No description provided for @settingVariant.
  ///
  /// In nl, this message translates to:
  /// **'Variant'**
  String get settingVariant;

  /// No description provided for @settingTieIsNat.
  ///
  /// In nl, this message translates to:
  /// **'Gelijke stand is nat'**
  String get settingTieIsNat;

  /// No description provided for @settingPitBonus.
  ///
  /// In nl, this message translates to:
  /// **'Bonus voor pit'**
  String get settingPitBonus;

  /// No description provided for @settingRoemThree.
  ///
  /// In nl, this message translates to:
  /// **'Roem: drie op rij'**
  String get settingRoemThree;

  /// No description provided for @settingRoemFour.
  ///
  /// In nl, this message translates to:
  /// **'Roem: vier op rij'**
  String get settingRoemFour;

  /// No description provided for @settingRoemStuk.
  ///
  /// In nl, this message translates to:
  /// **'Roem: stuk'**
  String get settingRoemStuk;

  /// No description provided for @settingRoemFourEqual.
  ///
  /// In nl, this message translates to:
  /// **'Roem: vier gelijke'**
  String get settingRoemFourEqual;

  /// No description provided for @settingRoemFourJacks.
  ///
  /// In nl, this message translates to:
  /// **'Roem: vier boeren'**
  String get settingRoemFourJacks;

  /// No description provided for @settingRounds.
  ///
  /// In nl, this message translates to:
  /// **'Aantal giffen (0 = onbeperkt)'**
  String get settingRounds;

  /// No description provided for @playingTeam.
  ///
  /// In nl, this message translates to:
  /// **'Spelende partij'**
  String get playingTeam;

  /// No description provided for @pitLabel.
  ///
  /// In nl, this message translates to:
  /// **'Pit (alle slagen gehaald)'**
  String get pitLabel;

  /// No description provided for @cardPointsLine.
  ///
  /// In nl, this message translates to:
  /// **'Kaartpunten: {playing} – {other}'**
  String cardPointsLine(int playing, int other);

  /// No description provided for @roemTitle.
  ///
  /// In nl, this message translates to:
  /// **'Roem'**
  String get roemTitle;

  /// No description provided for @roemHint.
  ///
  /// In nl, this message translates to:
  /// **'Tik = erbij, lang indrukken = eraf'**
  String get roemHint;

  /// No description provided for @roemTotal.
  ///
  /// In nl, this message translates to:
  /// **'Roem: {points}'**
  String roemTotal(int points);

  /// No description provided for @roemThree.
  ///
  /// In nl, this message translates to:
  /// **'Drie op rij'**
  String get roemThree;

  /// No description provided for @roemFour.
  ///
  /// In nl, this message translates to:
  /// **'Vier op rij'**
  String get roemFour;

  /// No description provided for @roemStuk.
  ///
  /// In nl, this message translates to:
  /// **'Stuk'**
  String get roemStuk;

  /// No description provided for @roemFourEqual.
  ///
  /// In nl, this message translates to:
  /// **'Vier gelijke'**
  String get roemFourEqual;

  /// No description provided for @roemFourJacks.
  ///
  /// In nl, this message translates to:
  /// **'Vier boeren'**
  String get roemFourJacks;

  /// No description provided for @natExplain.
  ///
  /// In nl, this message translates to:
  /// **'Nat: de tegenpartij krijgt alle punten en alle roem'**
  String get natExplain;

  /// No description provided for @pitExplain.
  ///
  /// In nl, this message translates to:
  /// **'Pit: alle slagen gehaald, met bonus'**
  String get pitExplain;

  /// No description provided for @choosePlaying.
  ///
  /// In nl, this message translates to:
  /// **'Kies eerst de spelende partij'**
  String get choosePlaying;

  /// No description provided for @cardsEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Vul de kaartpunten van de spelende partij in'**
  String get cardsEmpty;

  /// No description provided for @gameRikkenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Bieden, maat en nul-som uitbetaling'**
  String get gameRikkenDesc;

  /// No description provided for @rikRik.
  ///
  /// In nl, this message translates to:
  /// **'Rik (met maat)'**
  String get rikRik;

  /// No description provided for @rikTroela.
  ///
  /// In nl, this message translates to:
  /// **'Troela'**
  String get rikTroela;

  /// No description provided for @rikAlone.
  ///
  /// In nl, this message translates to:
  /// **'{number} alleen'**
  String rikAlone(int number);

  /// No description provided for @rikPiek.
  ///
  /// In nl, this message translates to:
  /// **'Piek'**
  String get rikPiek;

  /// No description provided for @rikMisere.
  ///
  /// In nl, this message translates to:
  /// **'Misère'**
  String get rikMisere;

  /// No description provided for @rikOpenPiek.
  ///
  /// In nl, this message translates to:
  /// **'Open piek'**
  String get rikOpenPiek;

  /// No description provided for @rikOpenMisere.
  ///
  /// In nl, this message translates to:
  /// **'Open misère'**
  String get rikOpenMisere;

  /// No description provided for @rikOpenPiekTalk.
  ///
  /// In nl, this message translates to:
  /// **'Open piek met praatje'**
  String get rikOpenPiekTalk;

  /// No description provided for @rikOpenMisereTalk.
  ///
  /// In nl, this message translates to:
  /// **'Open misère met praatje'**
  String get rikOpenMisereTalk;

  /// No description provided for @rikBidder.
  ///
  /// In nl, this message translates to:
  /// **'Wie biedt'**
  String get rikBidder;

  /// No description provided for @rikContract.
  ///
  /// In nl, this message translates to:
  /// **'Contract'**
  String get rikContract;

  /// No description provided for @rikPartner.
  ///
  /// In nl, this message translates to:
  /// **'Maat'**
  String get rikPartner;

  /// No description provided for @rikTricks.
  ///
  /// In nl, this message translates to:
  /// **'Slagen gehaald door de bieder (met maat)'**
  String get rikTricks;

  /// No description provided for @rikChooseBidder.
  ///
  /// In nl, this message translates to:
  /// **'Kies wie er biedt'**
  String get rikChooseBidder;

  /// No description provided for @rikChooseContract.
  ///
  /// In nl, this message translates to:
  /// **'Kies het contract'**
  String get rikChooseContract;

  /// No description provided for @rikChoosePartner.
  ///
  /// In nl, this message translates to:
  /// **'Kies de maat'**
  String get rikChoosePartner;

  /// No description provided for @rikChooseTricks.
  ///
  /// In nl, this message translates to:
  /// **'Kies het aantal slagen'**
  String get rikChooseTricks;

  /// No description provided for @rikMade.
  ///
  /// In nl, this message translates to:
  /// **'Gehaald'**
  String get rikMade;

  /// No description provided for @rikFailed.
  ///
  /// In nl, this message translates to:
  /// **'Niet gehaald'**
  String get rikFailed;

  /// No description provided for @zeroSum.
  ///
  /// In nl, this message translates to:
  /// **'Som van alle spelers: {sum}'**
  String zeroSum(int sum);

  /// No description provided for @rikBaseLabel.
  ///
  /// In nl, this message translates to:
  /// **'{contract}: basispunten'**
  String rikBaseLabel(String contract);

  /// No description provided for @settingPerTrick.
  ///
  /// In nl, this message translates to:
  /// **'Punten per over- of onderslag'**
  String get settingPerTrick;

  /// No description provided for @settingSlamBonus.
  ///
  /// In nl, this message translates to:
  /// **'Bonus voor alle 13 slagen (met maat)'**
  String get settingSlamBonus;

  /// No description provided for @settingMaatPays.
  ///
  /// In nl, this message translates to:
  /// **'Maat betaalt mee bij verlies'**
  String get settingMaatPays;

  /// No description provided for @gameHartenjagenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Strafpunten, schoppen vrouw en de maan'**
  String get gameHartenjagenDesc;

  /// No description provided for @heartsQueen.
  ///
  /// In nl, this message translates to:
  /// **'Schoppen Vrouw +{points}'**
  String heartsQueen(int points);

  /// No description provided for @heartsMoon.
  ///
  /// In nl, this message translates to:
  /// **'Maan'**
  String get heartsMoon;

  /// No description provided for @heartsMoonShot.
  ///
  /// In nl, this message translates to:
  /// **'De maan is geschoten'**
  String get heartsMoonShot;

  /// No description provided for @heartsHandedOut.
  ///
  /// In nl, this message translates to:
  /// **'Verdeeld: {points} van {total}'**
  String heartsHandedOut(int points, int total);

  /// No description provided for @settingTotalPoints.
  ///
  /// In nl, this message translates to:
  /// **'Strafpunten per ronde (totaal)'**
  String get settingTotalPoints;

  /// No description provided for @settingQueenPoints.
  ///
  /// In nl, this message translates to:
  /// **'Strafpunten Schoppen Vrouw'**
  String get settingQueenPoints;

  /// No description provided for @settingMoonEnabled.
  ///
  /// In nl, this message translates to:
  /// **'Maan schieten toestaan'**
  String get settingMoonEnabled;

  /// No description provided for @settingMoonMode.
  ///
  /// In nl, this message translates to:
  /// **'Bij de maan'**
  String get settingMoonMode;

  /// No description provided for @moonOthers.
  ///
  /// In nl, this message translates to:
  /// **'Anderen krijgen het totaal erbij'**
  String get moonOthers;

  /// No description provided for @moonShooter.
  ///
  /// In nl, this message translates to:
  /// **'Schutter krijgt het totaal eraf'**
  String get moonShooter;

  /// No description provided for @gameToepenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Punten tikken, op pelt en uitvallen'**
  String get gameToepenDesc;

  /// No description provided for @toepenOutBadge.
  ///
  /// In nl, this message translates to:
  /// **'uit'**
  String get toepenOutBadge;

  /// No description provided for @settingLimit.
  ///
  /// In nl, this message translates to:
  /// **'Uitvalgrens (strafpunten)'**
  String get settingLimit;

  /// No description provided for @settingPoverty.
  ///
  /// In nl, this message translates to:
  /// **'Markeer \'op pelt\' (nog 1 punt tot uit)'**
  String get settingPoverty;

  /// No description provided for @settingPlayOn.
  ///
  /// In nl, this message translates to:
  /// **'Doorspelen tot één speler over is'**
  String get settingPlayOn;

  /// No description provided for @gameJokeren.
  ///
  /// In nl, this message translates to:
  /// **'Jokeren'**
  String get gameJokeren;

  /// No description provided for @gameCanasta.
  ///
  /// In nl, this message translates to:
  /// **'Canasta'**
  String get gameCanasta;

  /// No description provided for @gameJokerenDesc.
  ///
  /// In nl, this message translates to:
  /// **'Bedragen optellen per ronde'**
  String get gameJokerenDesc;

  /// No description provided for @gameCanastaDesc.
  ///
  /// In nl, this message translates to:
  /// **'Teams, canasta\'s en doelscore'**
  String get gameCanastaDesc;

  /// No description provided for @undoLastAmount.
  ///
  /// In nl, this message translates to:
  /// **'Laatste bedrag ongedaan maken'**
  String get undoLastAmount;

  /// No description provided for @canastaMeldTitle.
  ///
  /// In nl, this message translates to:
  /// **'Minimale eerste meld'**
  String get canastaMeldTitle;

  /// No description provided for @quickJoker.
  ///
  /// In nl, this message translates to:
  /// **'Joker'**
  String get quickJoker;

  /// No description provided for @quickAce.
  ///
  /// In nl, this message translates to:
  /// **'Aas'**
  String get quickAce;

  /// No description provided for @quickFace.
  ///
  /// In nl, this message translates to:
  /// **'Plaatje'**
  String get quickFace;

  /// No description provided for @quickNaturalCanasta.
  ///
  /// In nl, this message translates to:
  /// **'Natuurlijke canasta'**
  String get quickNaturalCanasta;

  /// No description provided for @quickMixedCanasta.
  ///
  /// In nl, this message translates to:
  /// **'Gemengde canasta'**
  String get quickMixedCanasta;

  /// No description provided for @quickGoOut.
  ///
  /// In nl, this message translates to:
  /// **'Uitgaan'**
  String get quickGoOut;

  /// No description provided for @quickGoOutConcealed.
  ///
  /// In nl, this message translates to:
  /// **'Dicht uitgaan'**
  String get quickGoOutConcealed;

  /// No description provided for @quickRedThree.
  ///
  /// In nl, this message translates to:
  /// **'Rode drie'**
  String get quickRedThree;

  /// No description provided for @quickAllRedThrees.
  ///
  /// In nl, this message translates to:
  /// **'Alle rode drieën'**
  String get quickAllRedThrees;

  /// No description provided for @settingNaturalCanasta.
  ///
  /// In nl, this message translates to:
  /// **'Natuurlijke canasta'**
  String get settingNaturalCanasta;

  /// No description provided for @settingMixedCanasta.
  ///
  /// In nl, this message translates to:
  /// **'Gemengde canasta'**
  String get settingMixedCanasta;

  /// No description provided for @settingGoOut.
  ///
  /// In nl, this message translates to:
  /// **'Uitgaan'**
  String get settingGoOut;

  /// No description provided for @settingGoOutConcealed.
  ///
  /// In nl, this message translates to:
  /// **'Dicht uitgaan'**
  String get settingGoOutConcealed;

  /// No description provided for @settingRedThree.
  ///
  /// In nl, this message translates to:
  /// **'Rode drie'**
  String get settingRedThree;

  /// No description provided for @settingAllRedThrees.
  ///
  /// In nl, this message translates to:
  /// **'Alle vier rode drieën'**
  String get settingAllRedThrees;

  /// No description provided for @settingQuickJoker.
  ///
  /// In nl, this message translates to:
  /// **'Snelknop: joker'**
  String get settingQuickJoker;

  /// No description provided for @settingQuickAce.
  ///
  /// In nl, this message translates to:
  /// **'Snelknop: aas'**
  String get settingQuickAce;

  /// No description provided for @settingQuickFace.
  ///
  /// In nl, this message translates to:
  /// **'Snelknop: plaatje'**
  String get settingQuickFace;

  /// No description provided for @playersTab.
  ///
  /// In nl, this message translates to:
  /// **'Spelers'**
  String get playersTab;

  /// No description provided for @groupsTab.
  ///
  /// In nl, this message translates to:
  /// **'Groepen'**
  String get groupsTab;

  /// No description provided for @addGroup.
  ///
  /// In nl, this message translates to:
  /// **'Groep toevoegen'**
  String get addGroup;

  /// No description provided for @editGroup.
  ///
  /// In nl, this message translates to:
  /// **'Groep bewerken'**
  String get editGroup;

  /// No description provided for @groupName.
  ///
  /// In nl, this message translates to:
  /// **'Groepsnaam'**
  String get groupName;

  /// No description provided for @groupMembers.
  ///
  /// In nl, this message translates to:
  /// **'Leden'**
  String get groupMembers;

  /// No description provided for @noGroups.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen groepen. Maak een vast kaartgroepje om snel te starten.'**
  String get noGroups;

  /// No description provided for @deleteGroupConfirm.
  ///
  /// In nl, this message translates to:
  /// **'{name} verwijderen? Gespeelde spellen blijven bewaard.'**
  String deleteGroupConfirm(String name);

  /// No description provided for @startFromGroup.
  ///
  /// In nl, this message translates to:
  /// **'Start vanuit een groep'**
  String get startFromGroup;

  /// No description provided for @filterGame.
  ///
  /// In nl, this message translates to:
  /// **'Spel'**
  String get filterGame;

  /// No description provided for @filterGroup.
  ///
  /// In nl, this message translates to:
  /// **'Groep'**
  String get filterGroup;

  /// No description provided for @filterYear.
  ///
  /// In nl, this message translates to:
  /// **'Jaar'**
  String get filterYear;

  /// No description provided for @filterAll.
  ///
  /// In nl, this message translates to:
  /// **'Alle'**
  String get filterAll;

  /// No description provided for @historyNoMatch.
  ///
  /// In nl, this message translates to:
  /// **'Geen spellen met deze filters'**
  String get historyNoMatch;

  /// No description provided for @statsBest.
  ///
  /// In nl, this message translates to:
  /// **'Beste score'**
  String get statsBest;

  /// No description provided for @kaartkoningTitle.
  ///
  /// In nl, this message translates to:
  /// **'Kaartkoning {year}'**
  String kaartkoningTitle(int year);

  /// No description provided for @kaartkoningWins.
  ///
  /// In nl, this message translates to:
  /// **'{wins} winsten in {games} spellen'**
  String kaartkoningWins(int wins, int games);

  /// No description provided for @shareResult.
  ///
  /// In nl, this message translates to:
  /// **'Uitslag delen'**
  String get shareResult;

  /// No description provided for @shareImage.
  ///
  /// In nl, this message translates to:
  /// **'Deel als afbeelding'**
  String get shareImage;

  /// No description provided for @shareWatermark.
  ///
  /// In nl, this message translates to:
  /// **'Uitslag bijgehouden met de Kaartmaat App'**
  String get shareWatermark;

  /// No description provided for @padBackspace.
  ///
  /// In nl, this message translates to:
  /// **'Wis laatste cijfer'**
  String get padBackspace;

  /// No description provided for @padSign.
  ///
  /// In nl, this message translates to:
  /// **'Plus of min'**
  String get padSign;

  /// No description provided for @notAllowed.
  ///
  /// In nl, this message translates to:
  /// **'niet toegestaan'**
  String get notAllowed;

  /// No description provided for @undoAction.
  ///
  /// In nl, this message translates to:
  /// **'Ongedaan maken'**
  String get undoAction;

  /// No description provided for @entered.
  ///
  /// In nl, this message translates to:
  /// **'ingevuld'**
  String get entered;

  /// No description provided for @editing.
  ///
  /// In nl, this message translates to:
  /// **'wordt bewerkt'**
  String get editing;

  /// No description provided for @roundSaved.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} opgeslagen'**
  String roundSaved(int number);

  /// No description provided for @roundDeleted.
  ///
  /// In nl, this message translates to:
  /// **'Ronde {number} verwijderd'**
  String roundDeleted(int number);

  /// No description provided for @showProgress.
  ///
  /// In nl, this message translates to:
  /// **'Verloop bekijken'**
  String get showProgress;

  /// No description provided for @bidShort.
  ///
  /// In nl, this message translates to:
  /// **'bod {bid}'**
  String bidShort(int bid);

  /// No description provided for @bidAndWon.
  ///
  /// In nl, this message translates to:
  /// **'bod {bid} · {tricks}'**
  String bidAndWon(int bid, int tricks);

  /// No description provided for @toTricks.
  ///
  /// In nl, this message translates to:
  /// **'Naar slagen'**
  String get toTricks;

  /// No description provided for @teamPlayed.
  ///
  /// In nl, this message translates to:
  /// **'{team} speelden'**
  String teamPlayed(String team);

  /// No description provided for @pagePoints.
  ///
  /// In nl, this message translates to:
  /// **'Punten'**
  String get pagePoints;

  /// No description provided for @pageRoem.
  ///
  /// In nl, this message translates to:
  /// **'Roem'**
  String get pageRoem;

  /// No description provided for @cardPointsPair.
  ///
  /// In nl, this message translates to:
  /// **'{playTeam}: {playPoints} · {otherTeam}: {otherPoints}'**
  String cardPointsPair(
    String playTeam,
    int playPoints,
    String otherTeam,
    int otherPoints,
  );

  /// No description provided for @natShort.
  ///
  /// In nl, this message translates to:
  /// **'NAT'**
  String get natShort;

  /// No description provided for @pitShort.
  ///
  /// In nl, this message translates to:
  /// **'PIT'**
  String get pitShort;

  /// No description provided for @padClear.
  ///
  /// In nl, this message translates to:
  /// **'Alles wissen'**
  String get padClear;

  /// No description provided for @roemInTable.
  ///
  /// In nl, this message translates to:
  /// **'roem {points}'**
  String roemInTable(int points);

  /// No description provided for @natInTable.
  ///
  /// In nl, this message translates to:
  /// **'nat'**
  String get natInTable;

  /// No description provided for @pitInTable.
  ///
  /// In nl, this message translates to:
  /// **'pit'**
  String get pitInTable;

  /// No description provided for @rikOvertricks.
  ///
  /// In nl, this message translates to:
  /// **'Overslagen'**
  String get rikOvertricks;

  /// No description provided for @rikUndertricks.
  ///
  /// In nl, this message translates to:
  /// **'Onderslagen'**
  String get rikUndertricks;

  /// No description provided for @rikFewer.
  ///
  /// In nl, this message translates to:
  /// **'Eén minder'**
  String get rikFewer;

  /// No description provided for @rikMore.
  ///
  /// In nl, this message translates to:
  /// **'Eén meer'**
  String get rikMore;

  /// No description provided for @rikExactNote.
  ///
  /// In nl, this message translates to:
  /// **'Precies {target} slagen nodig'**
  String rikExactNote(int target);

  /// No description provided for @rikPartnerCrumb.
  ///
  /// In nl, this message translates to:
  /// **'maat {name}'**
  String rikPartnerCrumb(String name);

  /// No description provided for @rikResultCrumb.
  ///
  /// In nl, this message translates to:
  /// **'Uitslag'**
  String get rikResultCrumb;

  /// No description provided for @rikPartnerShort.
  ///
  /// In nl, this message translates to:
  /// **'maat'**
  String get rikPartnerShort;

  /// No description provided for @rikShortRik.
  ///
  /// In nl, this message translates to:
  /// **'Rik'**
  String get rikShortRik;

  /// No description provided for @rikShortOpenPiekTalk.
  ///
  /// In nl, this message translates to:
  /// **'Open piek + praat'**
  String get rikShortOpenPiekTalk;

  /// No description provided for @rikShortOpenMisereTalk.
  ///
  /// In nl, this message translates to:
  /// **'Open misère + praat'**
  String get rikShortOpenMisereTalk;

  /// No description provided for @heartsQueenShort.
  ///
  /// In nl, this message translates to:
  /// **'SV'**
  String get heartsQueenShort;

  /// No description provided for @heartsTooMany.
  ///
  /// In nl, this message translates to:
  /// **'Er zijn niet zoveel harten'**
  String get heartsTooMany;

  /// No description provided for @heartsQueenMissing.
  ///
  /// In nl, this message translates to:
  /// **'Wie heeft de Schoppen Vrouw?'**
  String get heartsQueenMissing;

  /// No description provided for @toepenPovertyBadge.
  ///
  /// In nl, this message translates to:
  /// **'op pelt'**
  String get toepenPovertyBadge;

  /// No description provided for @calcDone.
  ///
  /// In nl, this message translates to:
  /// **'Klaar'**
  String get calcDone;

  /// No description provided for @calcAdd.
  ///
  /// In nl, this message translates to:
  /// **'Bedrag optellen'**
  String get calcAdd;

  /// No description provided for @calcTapeEmpty.
  ///
  /// In nl, this message translates to:
  /// **'Nog geen bedragen'**
  String get calcTapeEmpty;

  /// No description provided for @saveRoundShort.
  ///
  /// In nl, this message translates to:
  /// **'Ronde opslaan'**
  String get saveRoundShort;

  /// No description provided for @pageDigits.
  ///
  /// In nl, this message translates to:
  /// **'Cijfers'**
  String get pageDigits;

  /// No description provided for @pageQuick.
  ///
  /// In nl, this message translates to:
  /// **'Snel'**
  String get pageQuick;

  /// No description provided for @nextRound.
  ///
  /// In nl, this message translates to:
  /// **'Volgende ronde'**
  String get nextRound;

  /// No description provided for @counterCustom.
  ///
  /// In nl, this message translates to:
  /// **'Eigen'**
  String get counterCustom;

  /// No description provided for @counterCustomStep.
  ///
  /// In nl, this message translates to:
  /// **'Eigen stap'**
  String get counterCustomStep;

  /// No description provided for @counterStepSemantics.
  ///
  /// In nl, this message translates to:
  /// **'Stap {number}'**
  String counterStepSemantics(int number);

  /// No description provided for @counterPlus.
  ///
  /// In nl, this message translates to:
  /// **'Plus {number}'**
  String counterPlus(int number);

  /// No description provided for @counterMinus.
  ///
  /// In nl, this message translates to:
  /// **'Min {number}'**
  String counterMinus(int number);

  /// No description provided for @counterThisRound.
  ///
  /// In nl, this message translates to:
  /// **'deze ronde {value}'**
  String counterThisRound(String value);
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
