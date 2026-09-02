import 'package:flutter/material.dart';

class Responsive {
  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;
  static const double largeDesktopMaxWidth = 1440;
  static const double contentMaxWidth = 720;
  static const double adminContentMaxWidth = 1100;

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < mobileMaxWidth;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= mobileMaxWidth &&
      MediaQuery.of(context).size.width < tabletMaxWidth;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= tabletMaxWidth;

  static bool isLargeDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= largeDesktopMaxWidth;

  static double getScreenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double getScreenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;

  static int getGridColumns(
    BuildContext context, {
    int mobile = 2,
    int tablet = 3,
    int desktop = 4,
    int? largeDesktop,
  }) {
    if (largeDesktop != null && isLargeDesktop(context)) return largeDesktop;
    if (isDesktop(context)) return desktop;
    if (isTablet(context)) return tablet;
    return mobile;
  }
}

/// A container that constrains content to a max width on larger screens (tablets, desktop web)
/// and centers it, preventing UI stretching.
class ResponsiveContentWrapper extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  const ResponsiveContentWrapper({
    super.key,
    required this.child,
    this.maxWidth = Responsive.contentMaxWidth,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
