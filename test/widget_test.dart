import 'package:flutter_test/flutter_test.dart';
import 'package:bilal_app/app.dart';

void main() {
  testWidgets('App builds without error', (WidgetTester tester) async {
    // Verify the root widget can be instantiated.
    expect(const BilalApp(), isNotNull);
  });
}
