import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:velocity_app/main.dart';
import 'package:velocity_app/providers/chat_provider.dart';

void main() {
  testWidgets('VelocityApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => ChatProvider(),
        child: const VelocityApp(hasCredentials: true),
      ),
    );
    expect(find.text('Velocity'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 300));
  });
}

