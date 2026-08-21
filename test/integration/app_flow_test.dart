import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:assignment/main.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('TaskFlow App launches and displays splash screen', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});

    await tester.pumpWidget(
      const ProviderScope(
        child: TaskFlowApp(),
      ),
    );

    expect(find.text('TaskFlow'), findsOneWidget);
    expect(find.text('Project & Task Management System'), findsOneWidget);

    await tester.pump(const Duration(milliseconds: 1500));
  });
}
