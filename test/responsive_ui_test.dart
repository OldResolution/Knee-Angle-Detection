import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gopal_app/services/preferences_service.dart';
import 'package:gopal_app/widgets/app_bottom_nav.dart';
import 'package:gopal_app/widgets/responsive/responsive_layout.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await PreferencesService.init();
  });

  testWidgets('ResponsiveLayout returns mobile scale values',
      (WidgetTester tester) async {
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
    expect(horizontalPadding, 12);
    expect(headlineSize, 22);
  });

  testWidgets('ResponsiveLayout returns tablet scale values',
      (WidgetTester tester) async {
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

  testWidgets('AppBottomNav renders dashboard destination on mobile width',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          bottomNavigationBar: AppBottomNav(currentIndex: 0),
        ),
      ),
    );

    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);
  });
}
