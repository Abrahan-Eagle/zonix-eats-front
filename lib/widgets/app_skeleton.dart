import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Universal shimmer/skeleton loading widget.
///
/// Use [AppSkeleton.listTile] for list placeholders or build custom layouts
/// with [AppSkeleton.box] and [AppSkeleton.circle].
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
      highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
      child: child,
    );
  }

  /// Rectangular placeholder box.
  static Widget box({double? width, double height = 16, double radius = 4}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
      );
    });
  }

  /// Circular placeholder.
  static Widget circle({double size = 40}) {
    return Builder(builder: (context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Shimmer.fromColors(
        baseColor: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
        highlightColor: isDark ? Colors.grey.shade700 : Colors.grey.shade100,
        child: Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        ),
      );
    });
  }

  /// Standard list tile placeholder (icon circle + 2 text lines).
  static Widget listTile() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          circle(size: 44),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                box(width: 160, height: 14),
                const SizedBox(height: 8),
                box(height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card-style placeholder (image block + title + subtitle).
  static Widget card() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          box(height: 140, radius: 12),
          const SizedBox(height: 12),
          box(width: 200, height: 16),
          const SizedBox(height: 8),
          box(width: 120, height: 12),
        ],
      ),
    );
  }

  /// Full-screen list placeholder with [count] items.
  /// When [cardHeight] is set, renders card-style blocks of that height.
  static Widget list({int count = 6, bool useCards = false, double? cardHeight}) {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      itemBuilder: (_, __) {
        if (cardHeight != null) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: box(height: cardHeight, radius: 12),
          );
        }
        return useCards ? card() : listTile();
      },
    );
  }
}

/// Drop-in replacement for `Center(child: CircularProgressIndicator())`.
/// Shows skeleton list or a custom child shimmer.
class AppSkeletonLoading extends StatelessWidget {
  const AppSkeletonLoading({super.key, this.itemCount = 6, this.useCards = false});

  final int itemCount;
  final bool useCards;

  @override
  Widget build(BuildContext context) {
    return AppSkeleton.list(count: itemCount, useCards: useCards);
  }
}
