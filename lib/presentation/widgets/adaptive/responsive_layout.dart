import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';

/// Responsive breakpoints for different screen sizes.
///
/// These breakpoints follow Material Design guidelines and common
/// responsive design practices:
/// - Mobile: < 600px (phones)
/// - Tablet: 600px - 1200px (tablets, small laptops)
/// - Desktop: >= 1200px (large screens, desktops)
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  /// Maximum width for mobile devices (exclusive).
  static const double mobile = 600.0;

  /// Minimum width for tablet devices (inclusive).
  static const double tablet = 600.0;

  /// Minimum width for desktop devices (inclusive).
  static const double desktop = 1200.0;
}

/// A widget that builds different layouts based on screen size.
///
/// This widget simplifies creating responsive layouts by providing
/// separate builders for mobile, tablet, and desktop screen sizes.
///
/// Example usage:
/// ```dart
/// ResponsiveLayout(
///   mobile: (context) => MobileLayout(),
///   tablet: (context) => TabletLayout(),
///   desktop: (context) => DesktopLayout(),
/// )
/// ```
///
/// You can also provide a single builder that receives the device type:
/// ```dart
/// ResponsiveLayout.builder(
///   builder: (context, deviceType) {
///     switch (deviceType) {
///       case DeviceType.mobile:
///         return MobileLayout();
///       case DeviceType.tablet:
///         return TabletLayout();
///       case DeviceType.desktop:
///         return DesktopLayout();
///     }
///   },
/// )
/// ```
class ResponsiveLayout extends StatelessWidget {
  /// Builder for mobile layout (< 600px).
  final WidgetBuilder mobile;

  /// Builder for tablet layout (600px - 1200px).
  /// If null, uses [mobile] builder.
  final WidgetBuilder? tablet;

  /// Builder for desktop layout (>= 1200px).
  /// If null, uses [tablet] builder, or [mobile] if tablet is also null.
  final WidgetBuilder? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Creates a responsive layout with a single builder that receives the device type.
  ///
  /// This is useful when you want to handle all device types in a single function.
  ///
  /// Example:
  /// ```dart
  /// ResponsiveLayout.builder(
  ///   builder: (context, deviceType) {
  ///     return Container(
  ///       padding: EdgeInsets.all(deviceType.isMobile ? 8.0 : 16.0),
  ///       child: MyContent(),
  ///     );
  ///   },
  /// )
  /// ```
  factory ResponsiveLayout.builder({
    Key? key,
    required Widget Function(BuildContext context, DeviceType deviceType)
    builder,
  }) {
    return ResponsiveLayout(
      key: key,
      mobile: (context) => builder(context, DeviceType.mobile),
      tablet: (context) => builder(context, DeviceType.tablet),
      desktop: (context) => builder(context, DeviceType.desktop),
    );
  }

  /// Creates a responsive layout that uses the same widget for all screen sizes,
  /// but provides different values based on the device type.
  ///
  /// This is useful for simple responsive adjustments like padding or font sizes.
  ///
  /// Example:
  /// ```dart
  /// ResponsiveLayout.value(
  ///   mobile: 8.0,
  ///   tablet: 16.0,
  ///   desktop: 24.0,
  ///   builder: (context, padding) {
  ///     return Container(
  ///       padding: EdgeInsets.all(padding),
  ///       child: MyContent(),
  ///     );
  ///   },
  /// )
  /// ```
  /// Creates a responsive layout that passes different values to a builder.
  ///
  /// This is useful when you need to provide different values (like padding,
  /// font size, etc.) based on screen size.
  static ResponsiveLayout withValue<T>({
    Key? key,
    required T mobile,
    T? tablet,
    T? desktop,
    required Widget Function(BuildContext context, T value) builder,
  }) {
    return ResponsiveLayout(
      key: key,
      mobile: (context) => builder(context, mobile),
      tablet: (context) => builder(context, tablet ?? mobile),
      desktop: (context) => builder(context, desktop ?? tablet ?? mobile),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Determine which builder to use based on screen width
    if (context.isDesktop) {
      return (desktop ?? tablet ?? mobile)(context);
    } else if (context.isTablet) {
      return (tablet ?? mobile)(context);
    } else {
      return mobile(context);
    }
  }
}

/// Enum representing different device types based on screen width.
enum DeviceType {
  /// Mobile device (< 600px)
  mobile,

  /// Tablet device (600px - 1200px)
  tablet,

  /// Desktop device (>= 1200px)
  desktop;

  /// Returns true if this is a mobile device.
  bool get isMobile => this == DeviceType.mobile;

  /// Returns true if this is a tablet device.
  bool get isTablet => this == DeviceType.tablet;

  /// Returns true if this is a desktop device.
  bool get isDesktop => this == DeviceType.desktop;

  /// Gets the device type from the given BuildContext.
  static DeviceType fromContext(BuildContext context) {
    if (context.isDesktop) {
      return DeviceType.desktop;
    } else if (context.isTablet) {
      return DeviceType.tablet;
    } else {
      return DeviceType.mobile;
    }
  }
}

/// Standard responsive spacing values for consistent UI across screen sizes.
///
/// These values follow a consistent scale:
/// - Mobile: Compact spacing for smaller screens
/// - Tablet: Medium spacing for touch-friendly layouts
/// - Desktop: Spacious layouts with more breathing room
class ResponsiveSpacing {
  ResponsiveSpacing._();

  /// Extra-small spacing: 4px (mobile) / 6px (tablet) / 8px (desktop)
  static const double xsm = 4.0;
  static const double xst = 6.0;
  static const double xsd = 8.0;

  /// Small spacing: 8px (mobile) / 12px (tablet) / 16px (desktop)
  static const double smm = 8.0;
  static const double smt = 12.0;
  static const double smd = 16.0;

  /// Medium spacing: 12px (mobile) / 16px (tablet) / 24px (desktop)
  static const double mdm = 12.0;
  static const double mdt = 16.0;
  static const double mdd = 24.0;

  /// Large spacing: 16px (mobile) / 24px (tablet) / 32px (desktop)
  static const double lgm = 16.0;
  static const double lgt = 24.0;
  static const double lgd = 32.0;

  /// Extra-large spacing: 24px (mobile) / 32px (tablet) / 48px (desktop)
  static const double xlm = 24.0;
  static const double xlt = 32.0;
  static const double xld = 48.0;
}

/// Extension methods for responsive layout on BuildContext.
extension ResponsiveLayoutExtensions on BuildContext {
  /// Gets the current device type based on screen width.
  ///
  /// Example:
  /// ```dart
  /// final deviceType = context.deviceType;
  /// if (deviceType.isMobile) {
  ///   // Show mobile-specific UI
  /// }
  /// ```
  DeviceType get deviceType => DeviceType.fromContext(this);

  /// Returns a value based on the current device type.
  ///
  /// This is a convenient helper for getting different values for different
  /// screen sizes without creating a full ResponsiveLayout widget.
  ///
  /// Example:
  /// ```dart
  /// final padding = context.responsiveValue(
  ///   mobile: 8.0,
  ///   tablet: 16.0,
  ///   desktop: 24.0,
  /// );
  /// ```
  T responsiveValue<T>({required T mobile, T? tablet, T? desktop}) {
    if (isDesktop) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Returns a widget based on the current device type.
  ///
  /// This is a convenient helper for building different widgets for different
  /// screen sizes without creating a full ResponsiveLayout widget.
  ///
  /// Example:
  /// ```dart
  /// context.responsiveWidget(
  ///   mobile: MobileLayout(),
  ///   tablet: TabletLayout(),
  ///   desktop: DesktopLayout(),
  /// )
  /// ```
  Widget responsiveWidget({
    required Widget mobile,
    Widget? tablet,
    Widget? desktop,
  }) {
    if (isDesktop) {
      return desktop ?? tablet ?? mobile;
    } else if (isTablet) {
      return tablet ?? mobile;
    } else {
      return mobile;
    }
  }

  /// Returns extra-small responsive spacing (4/6/8px).
  double get spacingXS => responsiveValue(
    mobile: ResponsiveSpacing.xsm,
    tablet: ResponsiveSpacing.xst,
    desktop: ResponsiveSpacing.xsd,
  );

  /// Returns small responsive spacing (8/12/16px).
  double get spacingS => responsiveValue(
    mobile: ResponsiveSpacing.smm,
    tablet: ResponsiveSpacing.smt,
    desktop: ResponsiveSpacing.smd,
  );

  /// Returns medium responsive spacing (12/16/24px).
  double get spacingM => responsiveValue(
    mobile: ResponsiveSpacing.mdm,
    tablet: ResponsiveSpacing.mdt,
    desktop: ResponsiveSpacing.mdd,
  );

  /// Returns large responsive spacing (16/24/32px).
  double get spacingL => responsiveValue(
    mobile: ResponsiveSpacing.lgm,
    tablet: ResponsiveSpacing.lgt,
    desktop: ResponsiveSpacing.lgd,
  );

  /// Returns extra-large responsive spacing (24/32/48px).
  double get spacingXL => responsiveValue(
    mobile: ResponsiveSpacing.xlm,
    tablet: ResponsiveSpacing.xlt,
    desktop: ResponsiveSpacing.xld,
  );

  /// Returns symmetric horizontal padding based on screen size.
  EdgeInsets get horizontalPadding =>
      EdgeInsets.symmetric(horizontal: spacingM);

  /// Returns standard screen padding (responsive on all sides).
  EdgeInsets get screenPadding => EdgeInsets.all(spacingM);
}
