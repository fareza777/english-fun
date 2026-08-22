import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Layout breakpoints, measured on the shortest side so a rotated tablet is
/// still treated as a tablet.
class Breakpoints {
  const Breakpoints._();

  /// Shortest side at which we consider the device a tablet.
  static const double tablet = 600;

  /// Shortest side for large tablets / desktop-class windows.
  static const double large = 900;

  /// Widest a single reading column should ever get. Beyond this, long lines
  /// and stretched cards start to look broken rather than generous.
  static const double contentMaxWidth = 820;
}

/// Device-class helpers derived from the current [MediaQuery].
extension ScreenSize on BuildContext {
  Size get _screen => MediaQuery.sizeOf(this);

  double get shortestSide => math.min(_screen.width, _screen.height);

  bool get isTablet => shortestSide >= Breakpoints.tablet;

  bool get isLargeTablet => shortestSide >= Breakpoints.large;

  bool get isLandscape => _screen.width > _screen.height;

  /// Columns for card grids: one on a phone, more as space allows.
  int get gridColumns {
    if (isLargeTablet) return isLandscape ? 3 : 2;
    if (isTablet) return 2;
    return 1;
  }

  /// Scales chunky UI (mascot, hero emoji) up a little on big screens so the
  /// layout does not look sparse.
  double get displayScale => isLargeTablet ? 1.25 : (isTablet ? 1.12 : 1.0);
}

/// Centres its child and stops it stretching into an unreadable ribbon on
/// wide screens. On phones it is a no-op.
class ContentWidth extends StatelessWidget {
  final Widget child;
  final double maxWidth;
  final AlignmentGeometry alignment;

  const ContentWidth({
    super.key,
    required this.child,
    this.maxWidth = Breakpoints.contentMaxWidth,
    this.alignment = Alignment.topCenter,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// Lays children out in one column on phones and a responsive grid on
/// tablets, without callers having to think about breakpoints.
///
/// Used for card lists (grades, units, shop items) where a single stretched
/// column wastes most of a tablet screen.
class AdaptiveCardGrid extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry padding;
  final double spacing;

  /// Exact height of one grid tile. Using a fixed extent rather than an
  /// aspect ratio keeps card height independent of column width, so a card
  /// that fits on a phone cannot silently overflow in a narrower tablet tile.
  final double itemHeight;

  const AdaptiveCardGrid({
    super.key,
    required this.children,
    required this.itemHeight,
    this.padding = EdgeInsets.zero,
    this.spacing = 16,
  });

  @override
  Widget build(BuildContext context) {
    final columns = context.gridColumns;
    if (columns <= 1) {
      return ListView.separated(
        padding: padding,
        itemCount: children.length,
        separatorBuilder: (_, _) => SizedBox(height: spacing),
        itemBuilder: (_, i) => children[i],
      );
    }
    return GridView.builder(
      padding: padding,
      itemCount: children.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        mainAxisExtent: itemHeight,
      ),
      itemBuilder: (_, i) => children[i],
    );
  }
}
