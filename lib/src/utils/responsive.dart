import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Screens at or above this shortest side are treated as tablets.
const double kTabletShortestSide = 600;

bool isTablet(BuildContext context) =>
    MediaQuery.sizeOf(context).shortestSide >= kTabletShortestSide;

/// Grid delegate that adds columns on wider screens and gives tiles more
/// height when the user has a larger system font, so cards don't overflow.
///
/// [aspectRatio] is the width / height used on a phone with default text size.
/// [horizontalPadding] is the total left + right padding around the grid.
SliverGridDelegate responsiveGridDelegate(
  BuildContext context, {
  required double aspectRatio,
  double minTileWidth = 160,
  double crossAxisSpacing = 16,
  double mainAxisSpacing = 16,
  double horizontalPadding = 40,
  int minColumns = 2,
  int maxColumns = 6,
}) {
  final width = MediaQuery.sizeOf(context).width - horizontalPadding;
  final columns = ((width + crossAxisSpacing) / (minTileWidth + crossAxisSpacing))
      .floor()
      .clamp(minColumns, maxColumns);

  final textScale = MediaQuery.textScalerOf(context).scale(10) / 10;
  final ratio = aspectRatio / (1 + math.max(0, textScale - 1) * 0.6);

  return SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: columns,
    crossAxisSpacing: crossAxisSpacing,
    mainAxisSpacing: mainAxisSpacing,
    childAspectRatio: ratio,
  );
}
