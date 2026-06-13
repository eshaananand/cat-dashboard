import 'package:cat_dashboard/main.dart';
import 'package:cat_dashboard/prep_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('dashboard renders the CAT tracker shell', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await PrepStore.load();

    await tester.pumpWidget(CatPrepApp(store: store));
    await tester.pumpAndSettle();

    expect(find.text('CAT 2026 Dashboard'), findsWidgets);
    expect(find.text('Syllabus done'), findsOneWidget);
    expect(find.text('Mocks done'), findsOneWidget);
  });
}
