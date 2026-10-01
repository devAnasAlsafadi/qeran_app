import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:qeran/core/widgets/paginated_list.dart';

/// Fifty 100-px rows in a 600-px viewport, inside the list.
Future<void> _pump(
  WidgetTester tester, {
  required bool hasMore,
  required Future<void> Function() onLoadMore,
  Future<void> Function()? onRefresh,
}) =>
    tester.pumpWidget(MaterialApp(
      home: Center(
        child: SizedBox(
          height: 600,
          child: PaginatedList(
            hasMore: hasMore,
            onRefresh: onRefresh ?? () async {},
            onLoadMore: onLoadMore,
            child: ListView.builder(
              itemCount: 50,
              itemExtent: 100,
              itemBuilder: (_, i) => Text('row $i'),
            ),
          ),
        ),
      ),
    ));

Future<void> _scrollBy(WidgetTester tester, double dy) async {
  await tester.drag(find.byType(ListView), Offset(0, -dy));
  await tester.pump();
}

void main() {
  testWidgets('far from the end, nothing loads', (tester) async {
    var loads = 0;
    await _pump(tester, hasMore: true, onLoadMore: () async => loads++);

    await _scrollBy(tester, 1000);

    expect(loads, 0);
  });

  testWidgets('near the end, the next page loads once while it is in flight',
      (tester) async {
    var loads = 0;
    var page = Completer<void>();
    await _pump(tester, hasMore: true, onLoadMore: () {
      loads++;
      return page.future;
    });

    // 5000 of content, 600 shown: 4400 is the end, 280 the threshold.
    await _scrollBy(tester, 4200);
    await _scrollBy(tester, 100);
    expect(loads, 1);

    page.complete();
    await tester.pump();
    page = Completer<void>();
    await _scrollBy(tester, -50);
    expect(loads, 2);
    page.complete();
  });

  testWidgets('no more pages: the end loads nothing', (tester) async {
    var loads = 0;
    await _pump(tester, hasMore: false, onLoadMore: () async => loads++);

    await _scrollBy(tester, 4400);

    expect(loads, 0);
  });

  testWidgets('pulling down at the top refreshes', (tester) async {
    var refreshes = 0;
    await _pump(
      tester,
      hasMore: true,
      onLoadMore: () async {},
      onRefresh: () async => refreshes++,
    );

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();

    expect(refreshes, 1);
  });
}
