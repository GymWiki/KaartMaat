import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'l10n/l10n.dart';

/// All outside links of the app, in one place.
abstract final class AppLinks {
  static final privacy = Uri.parse(
    'https://gymwiki.github.io/KaartMaat/privacy.html',
  );
  static final terms = Uri.parse(
    'https://gymwiki.github.io/KaartMaat/voorwaarden.html',
  );
  static const contactEmail = 'gymwiki25@gmail.com';
  static final contact = Uri(scheme: 'mailto', path: contactEmail);
}

/// Opens [uri] in the device's own browser or mail app. Tells the user when
/// nothing could open it (for example no mail app).
Future<void> openLink(BuildContext context, Uri uri) async {
  final messenger = ScaffoldMessenger.of(context);
  final failed = context.l10n.linkOpenFailed;
  var ok = false;
  try {
    ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  } catch (_) {}
  if (!ok) messenger.showSnackBar(SnackBar(content: Text(failed)));
}

/// Two small text links (privacy + terms), as stores expect near a purchase.
class LegalLinks extends StatelessWidget {
  const LegalLinks({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      alignment: WrapAlignment.center,
      children: [
        TextButton(
          onPressed: () => openLink(context, AppLinks.privacy),
          child: Text(l10n.privacyPolicy),
        ),
        TextButton(
          onPressed: () => openLink(context, AppLinks.terms),
          child: Text(l10n.termsOfUse),
        ),
      ],
    );
  }
}
