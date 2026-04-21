import 'package:flutter/material.dart';

class ResponsiveLayout {
  static const double mobileMaxWidth = 599;
  static const double tabletMaxWidth = 899;
  static const double compactMaxWidth = 420;

  static bool isCompact(BuildContext context) =>
      MediaQuery.of(context).size.width <= compactMaxWidth;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width <= mobileMaxWidth;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width > mobileMaxWidth && width <= tabletMaxWidth;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width > tabletMaxWidth;

  static double horizontalPadding(BuildContext context) {
    if (isCompact(context)) return 12;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  static double verticalPadding(BuildContext context) {
    if (isCompact(context)) return 16;
    if (isMobile(context)) return 20;
    if (isTablet(context)) return 24;
    return 32;
  }

  static double headlineSize(BuildContext context) {
    if (isCompact(context)) return 22;
    if (isMobile(context)) return 24;
    if (isTablet(context)) return 28;
    return 32;
  }

  static double sectionGap(BuildContext context) {
    if (isCompact(context)) return 14;
    if (isMobile(context)) return 16;
    if (isTablet(context)) return 20;
    return 24;
  }

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1280;
    if (isTablet(context)) return 980;
    return double.infinity;
  }

  static Widget constrainedPage(BuildContext context, Widget child) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}
