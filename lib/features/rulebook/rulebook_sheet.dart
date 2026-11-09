import 'package:flutter/material.dart';

import '../../core/l10n/l10n.dart';
import 'rulebook.dart';

/// Opens the rulebook of [type] in a tall bottom sheet. [settings] are the
/// rules of the running or upcoming game; the scoring section shows them.
Future<void> showRulebook(
  BuildContext context, {
  required String type,
  required Map<String, Object?> settings,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (_) => DraggableScrollableSheet(
    expand: false,
    initialChildSize: 0.95,
    minChildSize: 0.5,
    maxChildSize: 0.95,
    builder: (_, scroll) =>
        RulebookView(type: type, settings: settings, controller: scroll),
  ),
);

class RulebookView extends StatefulWidget {
  const RulebookView({
    super.key,
    required this.type,
    required this.settings,
    this.controller,
  });

  final String type;
  final Map<String, Object?> settings;
  final ScrollController? controller;

  @override
  State<RulebookView> createState() => _RulebookViewState();
}

class _RulebookViewState extends State<RulebookView> {
  late final Future<Rulebook> _book = Rulebook.load(
    widget.type,
    widget.settings,
  );
  final _keys = <String, GlobalKey>{};

  GlobalKey _key(String id) => _keys.putIfAbsent(id, GlobalKey.new);

  void _jump(String id) {
    final ctx = _key(id).currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return FutureBuilder<Rulebook>(
      future: _book,
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text(l10n.rulebookError));
        }
        final book = snap.data;
        if (book == null) {
          return const Center(child: CircularProgressIndicator());
        }
        final text = Theme.of(context).textTheme;
        final scheme = Theme.of(context).colorScheme;

        final sections = <(String, String, List<Widget>)>[
          (
            'goal',
            l10n.rulebookGoal,
            [for (final p in book.goal) _para(p, text)],
          ),
          (
            'needs',
            l10n.rulebookNeeds,
            [for (final p in book.needs) _bullet(p, text)],
          ),
          (
            'flow',
            l10n.rulebookFlow,
            [
              for (var i = 0; i < book.flow.length; i++)
                _numbered(i + 1, book.flow[i], text, scheme),
            ],
          ),
          (
            'scoring',
            l10n.rulebookScoring,
            [
              Text(
                l10n.rulebookScoringNote,
                style: text.bodySmall?.copyWith(color: scheme.primary),
              ),
              const SizedBox(height: 8),
              for (final p in book.scoringIntro) _para(p, text),
              if (book.scoringTable.isNotEmpty) _table(book, text, scheme),
              for (final p in book.scoringNotes) _bullet(p, text),
            ],
          ),
          if (book.rules.isNotEmpty)
            (
              'rules',
              l10n.rulebookRules,
              [
                for (final r in book.rules) ...[
                  Text(
                    r.title,
                    style: text.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  _para(r.text, text),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          if (book.tips.isNotEmpty)
            (
              'tips',
              l10n.rulebookTips,
              [for (final p in book.tips) _bullet(p, text)],
            ),
        ];

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '${l10n.rulebookTitle}: ${book.title}',
                  style: text.titleLarge,
                ),
              ),
            ),
            // always in view: jump to a section
            SizedBox(
              height: 48,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  for (final s in sections)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ActionChip(
                        label: Text(s.$2),
                        onPressed: () => _jump(s.$1),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                controller: widget.controller,
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final s in sections) ...[
                      Padding(
                        key: _key(s.$1),
                        padding: const EdgeInsets.only(top: 16, bottom: 8),
                        child: Text(
                          s.$2,
                          style: text.titleLarge?.copyWith(
                            color: scheme.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ...s.$3,
                    ],
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _para(String s, TextTheme text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(s, style: text.bodyLarge?.copyWith(height: 1.4)),
  );

  Widget _bullet(String s, TextTheme text) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('•  ', style: text.bodyLarge),
        Expanded(child: Text(s, style: text.bodyLarge?.copyWith(height: 1.4))),
      ],
    ),
  );

  Widget _numbered(int n, String s, TextTheme text, ColorScheme scheme) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 28,
              child: Text(
                '$n.',
                style: text.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.primary,
                ),
              ),
            ),
            Expanded(
              child: Text(s, style: text.bodyLarge?.copyWith(height: 1.4)),
            ),
          ],
        ),
      );

  Widget _table(Rulebook book, TextTheme text, ColorScheme scheme) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          for (var i = 0; i < book.scoringTable.length; i++)
            Container(
              color: i.isOdd ? scheme.surfaceContainerHighest : null,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      book.scoringTable[i].first,
                      style: text.bodyMedium,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: Text(
                      book.scoringTable[i].last,
                      textAlign: TextAlign.end,
                      style: text.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
