import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_app/screens/step_counter_screen.dart';
import 'package:gopal_app/widgets/responsive/responsive_layout.dart';

void main() {
  testWidgets('ResponsiveLayout returns mobile scale values', (WidgetTester tester) async {
    late bool isMobile;
    late double horizontalPadding;
    late double headlineSize;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(375, 812)),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              isMobile = ResponsiveLayout.isMobile(context);
              horizontalPadding = ResponsiveLayout.horizontalPadding(context);
              headlineSize = ResponsiveLayout.headlineSize(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(isMobile, isTrue);
    expect(horizontalPadding, 16);
    expect(headlineSize, 24);
  });

  testWidgets('ResponsiveLayout returns tablet scale values', (WidgetTester tester) async {
    late bool isTablet;
    late double horizontalPadding;
    late double headlineSize;

    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(size: Size(768, 1024)),
        child: MaterialApp(
          home: Builder(
            builder: (context) {
              isTablet = ResponsiveLayout.isTablet(context);
              horizontalPadding = ResponsiveLayout.horizontalPadding(context);
              headlineSize = ResponsiveLayout.headlineSize(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );

    expect(isTablet, isTrue);
    expect(horizontalPadding, 20);
    expect(headlineSize, 28);
  });

  testWidgets('StepCounter shows bottom navigation on mobile width', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(home: StepCounterScreen()),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Steps'), findsOneWidget);
  });
}
