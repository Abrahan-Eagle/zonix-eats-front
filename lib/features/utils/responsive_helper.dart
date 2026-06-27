import 'package:flutter/material.dart';

/// Breakpoints and responsive utilities for admin layouts.
///
/// - Mobile:  width < 600
/// - Tablet:  600 <= width < 1024
/// - Desktop: width >= 1024
///
/// On mobile (< 600) every widget renders exactly as before; responsive
/// logic only kicks in above that threshold.
class Responsive {
  Responsive._();

  static const double mobileBreakpoint = 600;
  static const double desktopBreakpoint = 1024;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobileBreakpoint;

  static bool isTablet(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= mobileBreakpoint && w < desktopBreakpoint;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktopBreakpoint;

  static int gridColumns(double width, {int mobile = 2, int tablet = 3, int desktop = 4}) {
    if (width >= desktopBreakpoint) return desktop;
    if (width >= mobileBreakpoint) return tablet;
    return mobile;
  }
}

/// Centers its [child] with a maximum width so content doesn't stretch
/// edge-to-edge on tablets/desktops.  On mobile the child fills the
/// available width as before.
class ResponsiveCenter extends StatelessWidget {
  const ResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }
    return content;
  }
}

/// A [SliverToBoxAdapter] variant of [ResponsiveCenter] for use inside
/// [CustomScrollView].
class SliverResponsiveCenter extends StatelessWidget {
  const SliverResponsiveCenter({
    super.key,
    required this.child,
    this.maxWidth = 900,
    this.padding,
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: ResponsiveCenter(
        maxWidth: maxWidth,
        padding: padding,
        child: child,
      ),
    );
  }
}

/// GridView that automatically picks [crossAxisCount] based on the
/// available width using [LayoutBuilder].
class AdaptiveGrid extends StatelessWidget {
  const AdaptiveGrid({
    super.key,
    required this.children,
    this.mobileColumns = 2,
    this.tabletColumns = 3,
    this.desktopColumns = 4,
    this.mainAxisSpacing = 12,
    this.crossAxisSpacing = 12,
    this.childAspectRatio = 1.0,
    this.shrinkWrap = true,
    this.padding,
  });

  final List<Widget> children;
  final int mobileColumns;
  final int tabletColumns;
  final int desktopColumns;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final double childAspectRatio;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = Responsive.gridColumns(
          constraints.maxWidth,
          mobile: mobileColumns,
          tablet: tabletColumns,
          desktop: desktopColumns,
        );
        return GridView.count(
          crossAxisCount: columns,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
          childAspectRatio: childAspectRatio,
          shrinkWrap: shrinkWrap,
          physics: const NeverScrollableScrollPhysics(),
          padding: padding,
          children: children,
        );
      },
    );
  }
}
