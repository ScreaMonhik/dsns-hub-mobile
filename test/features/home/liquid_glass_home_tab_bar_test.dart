import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dsns_hub/features/home/presentation/widgets/liquid_glass_home_tab_bar.dart';

void main() {
  testWidgets('liquid glass tab bar paints over scrolling content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            fit: StackFit.expand,
            children: [
              ColoredBox(color: Color(0xFF1E40AF)),
              LiquidGlassHomeTabBar(
                child: Center(child: Text('Чати')),
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Чати'), findsOneWidget);
    expect(find.byType(LiquidGlassHomeTabBar), findsOneWidget);
  });
}
