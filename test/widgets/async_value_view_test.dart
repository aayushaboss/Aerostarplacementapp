import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aerostar_edge/widgets/async_value_view.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('shows a loading spinner before the loader resolves', (tester) async {
    await tester.pumpWidget(wrap(AsyncValueView<int>(
      loader: () => Future.delayed(const Duration(milliseconds: 50), () => 1),
      builder: (context, value) => Text('value: $value'),
    )));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('value: 1'), findsNothing);

    // Drain the pending delayed Future so it doesn't leak a timer past
    // this test's own teardown.
    await tester.pumpAndSettle();
  });

  testWidgets('renders the builder once data arrives', (tester) async {
    await tester.pumpWidget(wrap(AsyncValueView<int>(
      loader: () async => 42,
      builder: (context, value) => Text('value: $value'),
    )));

    await tester.pumpAndSettle();

    expect(find.text('value: 42'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows an EmptyState-style error view with retry on failure', (tester) async {
    var attempts = 0;
    await tester.pumpWidget(wrap(AsyncValueView<int>(
      loader: () async {
        attempts++;
        if (attempts == 1) throw Exception('boom');
        return 7;
      },
      builder: (context, value) => Text('value: $value'),
    )));

    await tester.pumpAndSettle();

    expect(find.text("Couldn't load this"), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();

    expect(find.text('value: 7'), findsOneWidget);
  });

  testWidgets('renders the empty builder when isEmpty matches', (tester) async {
    await tester.pumpWidget(wrap(AsyncValueView<List<int>>(
      loader: () async => <int>[],
      isEmpty: (list) => list.isEmpty,
      emptyBuilder: (context) => const Text('nothing here'),
      builder: (context, list) => Text('count: ${list.length}'),
    )));

    await tester.pumpAndSettle();

    expect(find.text('nothing here'), findsOneWidget);
    expect(find.textContaining('count:'), findsNothing);
  });
}
