import 'package:dramacircle/src/app.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('renders app shell', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: DramaCircleApp()));
    await tester.pump();
    expect(find.byType(DramaCircleApp), findsOneWidget);
  });
}
