import 'package:flutter_test/flutter_test.dart';
import 'package:kaartmaat/core/links.dart';

import '../helpers.dart';

void main() {
  test('links point at the GitHub Pages site', () {
    expect(
      AppLinks.privacy.toString(),
      'https://gymwiki.github.io/KaartMaat/privacy.html',
    );
    expect(
      AppLinks.terms.toString(),
      'https://gymwiki.github.io/KaartMaat/voorwaarden.html',
    );
    expect(AppLinks.contact.toString(), 'mailto:gymwiki25@gmail.com');
  });

  testWidgets('LegalLinks shows privacy and terms', (tester) async {
    await pumpApp(tester, const LegalLinks());
    expect(find.text('Privacyverklaring'), findsOneWidget);
    expect(find.text('Gebruiksvoorwaarden'), findsOneWidget);
  });
}
