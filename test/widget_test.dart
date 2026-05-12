import 'package:flutter_test/flutter_test.dart';
import 'package:uni_project/main.dart';

void main() {
  testWidgets('shows the Fit Diary start screen', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Fit Diary'), findsOneWidget);
    expect(find.text('Exercise Guide'), findsOneWidget);
    expect(find.text('Workout Log'), findsOneWidget);
    expect(find.text('Meals'), findsOneWidget);
    expect(find.text('Notes'), findsOneWidget);
  });
}
