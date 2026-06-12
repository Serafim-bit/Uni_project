import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/main.dart';
import 'package:uni_project/start/card_for_start.dart';

Future<void> pumpUi(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

Future<void> pumpUntilFound(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isNotEmpty) return;
  }

  final visibleText = find
      .byType(Text)
      .evaluate()
      .map((element) => (element.widget as Text).data)
      .whereType<String>()
      .toList();
  fail('Expected finder to appear. Visible text: $visibleText');
}

Future<void> pumpUntilGone(WidgetTester tester, Finder finder) async {
  for (var i = 0; i < 120; i++) {
    await tester.runAsync(() async {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    });
    await tester.pump(const Duration(milliseconds: 100));
    if (finder.evaluate().isEmpty) return;
  }

  fail('Expected finder to disappear.');
}

Finder startCard(String title) {
  return find.byWidgetPredicate(
    (widget) => widget is CardForStart && widget.title == title,
    description: 'start card "$title"',
  );
}

Future<void> tapStartCard(WidgetTester tester, String title) async {
  await tester.ensureVisible(startCard(title));
  await tester.pump();
  await tester.tap(find.text(title));
}

Future<void> pumpFitDiary(
  WidgetTester tester, {
  Size viewSize = const Size(390, 844),
}) async {
  tester.view.physicalSize = viewSize;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(const MyApp());
  await pumpUntilFound(tester, startCard('Nutrition'));
}

Future<void> dragBottomSheetToActions(WidgetTester tester) async {
  FocusManager.instance.primaryFocus?.unfocus();
  tester.testTextInput.hide();
  await tester.pump();
  final logicalSize = tester.view.physicalSize / tester.view.devicePixelRatio;
  final start = Offset(logicalSize.width / 2, logicalSize.height - 80);
  for (var i = 0; i < 4; i++) {
    await tester.dragFrom(start, const Offset(0, -420));
    await tester.pump();
  }
}
