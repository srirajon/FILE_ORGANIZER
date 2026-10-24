import 'package:flutter_test/flutter_test.dart';
import 'package:file_organizer/main.dart';

void main() {
  testWidgets('File Organizer App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const FileOrganizerApp());
    expect(find.text('File Organizer'), findsOneWidget);
  });
}
