import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';

void main() {
  testWidgets('Wearcast opens on the account screen', (tester) async {
    await tester.pumpWidget(const WearcastApp());

    expect(find.text('Wearcast'), findsWidgets);
    expect(find.text('Create Account'), findsOneWidget);
  });
}
