import '../../../core/l10n/l10n.dart';

String rikContractName(AppLocalizations l, String id) => switch (id) {
      'rik' => l.rikRik,
      'troela' => l.rikTroela,
      'alone8' => l.rikAlone(8),
      'alone9' => l.rikAlone(9),
      'alone10' => l.rikAlone(10),
      'alone11' => l.rikAlone(11),
      'alone12' => l.rikAlone(12),
      'alone13' => l.rikAlone(13),
      'piek' => l.rikPiek,
      'misere' => l.rikMisere,
      'openPiek' => l.rikOpenPiek,
      'openMisere' => l.rikOpenMisere,
      'openPiekTalk' => l.rikOpenPiekTalk,
      'openMisereTalk' => l.rikOpenMisereTalk,
      _ => id,
    };
