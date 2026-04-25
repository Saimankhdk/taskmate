// Basic smoke test for TaskMate root widget.

import 'package:flutter_test/flutter_test.dart';

import 'package:capstone_project/main.dart';

void main() {
  testWidgets('TaskMate shows splash title', (WidgetTester tester) async {
    final appState = AppState();
    await tester.pumpWidget(TaskMateApp(appState: appState));
    expect(find.text('TaskMate'), findsOneWidget);
    // SplashScreen uses Future.delayed(2200ms) before navigating; flush the timer.
    await tester.pump(const Duration(milliseconds: 2500));
  });

  testWidgets('Splash routes to login when Firebase is unavailable', (
    WidgetTester tester,
  ) async {
    final appState = AppState();
    await tester.pumpWidget(TaskMateApp(appState: appState));

    await tester.pump(const Duration(milliseconds: 2300));
    await tester.pumpAndSettle(const Duration(milliseconds: 500));
    expect(find.byType(LoginScreen), findsOneWidget);
  });
}
