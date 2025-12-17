import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strategic_logger/logger.dart';
import 'package:strategic_logger/src/strategies/console/console_log_strategy.dart';

import 'package:example/main.dart';

void main() {
  testWidgets('Strategic Logger Example app smoke test', (
    WidgetTester tester,
  ) async {
    // Initialize logger for testing
    await logger.initialize(
      strategies: [
        ConsoleLogStrategy(useModernFormatting: false, showContext: true),
      ],
      level: LogLevel.debug,
      force: true,
    );

    // Build our app and trigger a frame.
    await tester.pumpWidget(const StrategicLoggerExampleApp());

    // Verify that the app title is present
    expect(find.text('Strategic Logger Demo'), findsOneWidget);

    // Verify that key UI elements are present
    expect(find.text('Total Logs'), findsOneWidget);
    expect(find.text('Log Levels'), findsOneWidget);
    expect(find.text('Special Features'), findsOneWidget);
    expect(find.text('Context Examples'), findsOneWidget);

    // Verify that log level buttons are present
    expect(find.text('Debug'), findsOneWidget);
    expect(find.text('Info'), findsOneWidget);
    expect(find.text('Warning'), findsOneWidget);
    expect(find.text('Error'), findsOneWidget);
    expect(find.text('Fatal'), findsOneWidget);

    // Tap the floating action button (Quick Log)
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that the log count has incremented
    // (The UI should show the updated count)

    // Cleanup
    logger.dispose();
  });
}
