import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:assignment/domain/entities/task.dart';
import 'package:assignment/presentation/widgets/status_badge.dart';
import 'package:assignment/presentation/widgets/priority_badge.dart';

void main() {
  testWidgets('StatusBadge and PriorityBadge render correct labels and colors', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              StatusBadge(status: TaskStatus.inProgress),
              PriorityBadge(priority: TaskPriority.urgent),
            ],
          ),
        ),
      ),
    );

    expect(find.text('In Progress'), findsOneWidget);
    expect(find.text('Urgent'), findsOneWidget);
  });
}
