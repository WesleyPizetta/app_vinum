import 'package:flutter/material.dart';

class VinumErrorIcon extends StatelessWidget {
  final double size;
  final double? iconSize;
  final Color? backgroundColor;
  final Color iconColor;

  const VinumErrorIcon({
    super.key,
    this.size = 80,
    this.iconSize,
    this.backgroundColor,
    this.iconColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    final color = backgroundColor ?? Theme.of(context).colorScheme.error;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.close_rounded,
        color: iconColor,
        size: iconSize ?? size * 0.55,
      ),
    );
  }
}
