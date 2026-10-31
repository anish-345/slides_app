import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:slides_app/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('Avionti Studio App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AviontiSlidesStudioApp());
    await tester.pumpAndSettle();
    expect(find.textContaining('Avionti'), findsWidgets);
  });
}
